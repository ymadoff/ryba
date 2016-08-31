
# Solr Install

    module.exports = header: 'Solr Cloud Docker Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_dir  = solr.cloud_docker.tmp_dir ?= "/var/tmp/ryba/solr"
      protocol = if solr.cloud_docker.ssl.enabled then 'https' else 'http'

## Dependencies

      @call once:true, 'masson/commons/java'
      @call 'masson/core/krb5_client/wait'
      @call 'ryba/zookeeper/server/wait'
      @register 'write_jaas', 'ryba/lib/write_jaas'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      
## Layout

      @mkdir
        target: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @mkdir
        directory: solr.cloud_docker.conf_dir
        uid: solr.user.name
        gid: solr.group.name
      
## Users and Groups

      @group solr.group
      @user solr.user
        
## Config

      @render
        header: 'Solr Config'
        source: solr.cloud_docker.conf_source
        target: "#{solr.cloud_docker.conf_dir}/solr.xml"
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
        context: @
        local: true
        backup: true
        eof: true

## Kerberos

      @krb5_addprinc
        unless_exists: solr.cloud_docker.spnego.keytab
        header: 'Kerberos SPNEGO'
        principal: solr.cloud_docker.spnego.principal
        randkey: true
        keytab: solr.cloud_docker.spnego.keytab
        uid: solr.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @execute
        header: 'SPNEGO'
        cmd: "su -l #{solr.user.name} -c 'test -r #{solr.cloud_docker.spnego.keytab}'"
      @krb5_addprinc
        header: 'Solr Super User'
        principal: solr.cloud_docker.admin_principal
        password: solr.cloud_docker.admin_password
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        header: 'Solr JAAS'
        target: "#{solr.cloud_docker.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: solr.cloud_docker.spnego.principal
            keyTab: solr.cloud_docker.spnego.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: solr.user.name
        gid: solr.group.name
      @krb5_addprinc
        header: 'Solr Server User'
        principal: solr.cloud_docker.principal
        keytab: solr.cloud_docker.keytab
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## SSL Certificate
        
      @download
        source: ssl.cacert
        target: "/etc/docker/certs.d/ca.pem"
        mode: 0o0640
        shy: true
      @download
        source: ssl.cert
        target: "/etc/docker/certs.d/cert.pem"
        mode: 0o0640
        shy: true
      @download
        source: ssl.key
        target: "/etc/docker/certs.d/key.pem"
        mode: 0o0640
        shy: true

## Container
Ryba support installing solr from apache official release or HDP Search repos.
      
      @download
        binary: true
        header: 'Download docker container'
        source: "#{solr.cloud_docker.build.dir}/#{solr.cloud_docker.build.tar}"
        target: "#{tmp_dir}/solr.tar"
      @call 
        header: 'Check container', handler: (opts, callback) =>
          checksum  = ''
          @docker_checksum
            docker:
              host: "tcp://#{@config.host}:#{solr.cloud_docker.port ? 2376}"
              tlsverify:" "
              tlscacert: "/etc/docker/certs.d/ca.pem"
              tlscert: "/etc/docker/certs.d/cert.pem"
              tlskey: "/etc/docker/certs.d/key.pem"
            image: solr.cloud_docker.build.image
            tag: solr.cloud_docker.build.version
          , (err, status, chk) ->
            return callback err if err
            checksum = chk
            opts.log "Found image with checksum: #{checksum}" unless !checksum
            if !checksum then callback null, true else callback null, false
      @docker_load
        header: 'Load container to docker'
        if: -> @status -1 or @status -2
        source: "#{tmp_dir}/solr.tar"
        docker:
          host: "tcp://#{@config.host}:#{solr.cloud_docker.port ? 2376}"
          tlsverify:" "
          tlscacert: "/etc/docker/certs.d/ca.pem"
          tlscert: "/etc/docker/certs.d/cert.pem"
          tlskey: "/etc/docker/certs.d/key.pem"
 
## SSL

      @java_keystore_add
        keystore: solr.cloud_docker.ssl_keystore_path
        storepass: solr.cloud_docker.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.cloud_docker.ssl_keystore_pwd
        name: @config.shortname
        local: true
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      @java_keystore_add
        keystore: solr.cloud_docker.ssl_truststore_path
        storepass: solr.cloud_docker.ssl_truststore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local: true
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      @chown
        target: solr.cloud_docker.ssl_truststore_path
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      @chown
        target: solr.cloud_docker.ssl_keystore_path
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      
      @call header: 'Cluster Configuration', handler: (_, callback) ->
        counter = 0
        each(Object.keys(solr.cloud_docker.clusters))
        .parallel(false)
        .call (name, i, next) =>
          config = solr.cloud_docker.clusters[name] # get cluster config
          config_host = config.config_hosts["#{@config.host}"] # get host config for the cluster
          return next() unless config_host?
          config_host.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
          config_host.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of config_host.auth_opts
          writes = for k,v of config_host.env
            match: RegExp "^.*#{k}=.*$", 'mg'
            replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
            append: true
          @call header: 'IPTables', handler: ->
            return unless @config.iptables.action is 'start'
            @iptables
              rules: [
                { chain: 'INPUT', jump: 'ACCEPT', dport: config.port, protocol: 'tcp', state: 'NEW', comment: "Solr Cluster #{name}" }
              ]
          @mkdir
            header: 'Solr Cluster Configuration'
            target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}"
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @mkdir
            header: 'Solr Cluster Log dir'
            target: config.log_dir
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @mkdir
            header: 'Solr Cluster Pid dir'
            target: config.pid_dir
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @mkdir
            header: 'Solr Cluster Data dir'
            target: config.data_dir
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @write
            header: 'Security config'
            content: JSON.stringify config_host.security
            target: "#{config.data_dir}/security.json"
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @render
            source:"#{__dirname}/../resources/cloud_docker/docker_entrypoint.sh"
            target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker_entrypoint.sh"
            context: @config
            local: true
            local: true
            backup: true
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @render
            header: 'Solr Environment'
            source: "#{__dirname}/../resources/cloud/solr.ini.sh.j2"
            target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/solr.in.sh"
            context: @config
            write: writes
            local: true
            backup: true
            eof: true
            uid: solr.user.name
            gid: solr.group.name
            mode: 0o0755
          @call -> 
            for node in [1..config.containers]
              config.service_def["node_#{node}"]['depends_on'] = ["node_#{config.master_node}"] if node != config.master_node
          @write_yaml
            if: @config.host is config['master']
            header: 'Generation docker-compose'
            target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker-compose.yml"
            content:  
              version:'2'
              services: config.service_def
          @then next
        .then (err) -> callback err 
          
## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
    each = require 'each'
