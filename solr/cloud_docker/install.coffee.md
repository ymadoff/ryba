
# Solr Cloud Docker Install

    module.exports = header: 'Solr Cloud Docker Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_dir  = solr.cloud_docker.tmp_dir ?= "/var/tmp/ryba/solr"
      hosts = @contexts('ryba/solr/cloud_docker').map (ctx) -> ctx.config.host
      solr.cloud_docker.build.dir = '/tmp/solr/build'

## Dependencies

      @call 'masson/core/krb5_client/wait'
      @call 'ryba/zookeeper/server/wait'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users and Groups
Create user and groups for solr user.

      @mkdir
        target: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @group solr.group
      @user solr.user

## Layout

      @mkdir
        target: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @mkdir
        directory: solr.cloud_docker.conf_dir
        uid: solr.user.name
        gid: solr.group.name

## Kerberos

      @krb5_addprinc
        unless_exists: solr.cloud_docker.spnego.keytab
        header: 'Kerberos SPNEGO'
        principal: solr.cloud_docker.spnego.principal
        randkey: true
        keytab: solr.cloud_docker.spnego.keytab
        gid: hadoop_group.name
        mode: 0o660
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
      @file.jaas
        header: 'Solr JAAS'
        target: "#{solr.cloud_docker.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: solr.cloud_docker.principal
            keyTab: solr.cloud_docker.keytab
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

      @file.download
        source: ssl.cacert
        target: "/etc/docker/certs.d/ca.pem"
        mode: 0o0640
        shy: true
      @file.download
        source: ssl.cert
        target: "/etc/docker/certs.d/cert.pem"
        mode: 0o0640
        shy: true
      @file.download
        source: ssl.key
        target: "/etc/docker/certs.d/key.pem"
        mode: 0o0640
        shy: true

## Container
Ryba support installing solr from apache official release or HDP Search repos.
Priority to docker pull function to get the solr container, else a tar should
be prepared in the mecano cache dir.

      @call header: 'Load Container', handler: ->
        exists = false
        @docker.checksum
          docker: solr.cloud_docker.swarm_conf
          image: solr.cloud_docker.build.image
          tag: solr.cloud_docker.version
        , (err, status, checksum) ->
          throw err if err
          exists = checksum
        @docker.pull
          header: 'Pull container'
          if: -> not exists
          tag: solr.cloud_docker.build.image
          version: solr.cloud_docker.version
          code_skipped: 1
        @file.download
          unless: -> @status(-1) or @status(-2)
          binary: true
          header: 'Download container'
          source: solr.cloud_docker.build.source
          target: "#{tmp_dir}/solr.tar"
        @docker.load
          header: 'Load container to docker'
          unless: -> @status(-3)
          if_exists: "#{tmp_dir}/solr.tar"
          source: "#{tmp_dir}/solr.tar"
          docker: solr.cloud_docker.swarm_conf

## User Limits

      @system.limits
        header: 'Ulimit'
        user: solr.user.name
      , solr.user.limits

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

## Cluster Specific configuration
Here we loop through the clusters definition to write container specific file
configuration like solr.in.sh or solr.xml.
      
      @each solr.cloud_docker.clusters, (options, callback) ->
        counter = 0
        name = options.key
        config = solr.cloud_docker.clusters[name] # get cluster config
        config_host = config.config_hosts["#{@config.host}"] # get host config for the cluster
        dockerfile = null
        return callback() unless config_host?
        switch config.docker_compose_version
          when '1' 
            dockerfile = config.service_def
            break;
          when '2' 
            dockerfile =
              version:'2'
              services: config.service_def
            break;
        config_host.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        config_host.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of config_host.auth_opts
        writes = for k,v of config_host.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @call header: 'IPTables', handler: ->
          return unless @config.iptables.action is 'start'
          @tools.iptables
            rules: [
              { chain: 'INPUT', jump: 'ACCEPT', dport: config.port, protocol: 'tcp', state: 'NEW', comment: "Solr Cluster #{name}" }
            ]
        @mkdir
          header: 'Solr Cluster Configuration'
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @mkdir
          header: 'Solr Cluster Log dir'
          target: config.log_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @mkdir
          header: 'Solr Cluster Pid dir'
          target: config.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: config.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          perm: '0750'
        @mkdir
          header: 'Solr Cluster Data dir'
          target: config.data_dir
          mode: 0o0750
        @chown
          target: config.data_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @file
          header: 'Security config'
          content: JSON.stringify config_host.security
          target: "#{config.data_dir}/security.json"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @render
          source:"#{__dirname}/../resources/cloud_docker/docker_entrypoint.sh"
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker_entrypoint.sh"
          context: @config
          local: true
          local: true
          backup: true
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @render
          source:"#{__dirname}/../resources/cloud_docker/zkCli.sh.j2"
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/zkCli.sh"
          context: @config.ryba
          local: true
          local: true
          backup: true
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
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
          mode: 0o0750
        @call
          unless: config.docker_compose_version is '1'
          shy: true
          handler: ->
            for node in [1..config.containers]
              config.service_def["node_#{node}"]['depends_on'] = ["node_#{config.master_node}"] if node != config.master_node
        @call 
          header: 'Solr xml config'
        , ->
          for host in config.hosts
            root = builder.create('solr').dec '1.0', 'UTF-8', true 
            solrcloud = root.ele 'solrcloud'
            solrcloud.ele 'str', {'name':'host'}, "#{@config.host}"
            solrcloud.ele 'str', {'name':'hostPort'}, "#{config.port}"
            solrcloud.ele 'str', {'name':'hostContext'}, '${hostContext:solr}'
            solrcloud.ele 'bool', {'name':'genericCoreNodeNames'}, '${genericCoreNodeNames:true}'
            solrcloud.ele 'str', {'name':'zkCredentialsProvider'}, "#{config_host.zk_opts.zkCredentialsProvider}"
            solrcloud.ele 'str', {'name':'zkACLProvider'}, "#{config_host.zk_opts.zkACLProvider}"
            solrcloud.ele 'int', {'name':'zkClientTimeout'}, '${zkClientTimeout:30000}'
            solrcloud.ele 'int', {'name':'distribUpdateSoTimeout'}, '${distribUpdateSoTimeout:600000}'
            solrcloud.ele 'int', {'name':'distribUpdateConnTimeout'}, '${distribUpdateConnTimeout:60000}'
            solrcloud.ele 'str', {'name':'zkHost'}, "#{config_host['env']['ZK_HOST']}"
            shardHandlerFactory = solrcloud.ele 'shardHandlerFactory', {'name':'shardHandlerFactory','class':'HttpShardHandlerFactory'}
            shardHandlerFactory.ele 'int', {'name':'socketTimeout'}, '${socketTimeout:600000}'
            shardHandlerFactory.ele 'int', {'name':'connTimeout'}, '${connTimeout:60000}'
            @file
              if: host is @config.host
              header: 'Solr Config'
              target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/solr.xml"
              uid: solr.user.name
              gid: solr.group.name
              content: root.end pretty:true
              mode: 0o0750
              backup: true
              eof: true
            @render
              if: host is @config.host
              header: 'Log4j'
              source: "#{__dirname}/../resources/log4j.properties.j2"
              target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/log4j.properties"
              local_source: true
        @file.yaml
          if: @config.host is config['master'] or not @config.docker.swarm?
          header: 'Generation docker-compose'
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker-compose.yml"
          content: dockerfile
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0750
        @docker.compose.up
          header: 'Compose up through swarm'
          if: @config.host is config['master'] and (@has_service('ryba/swarm/agent') or @has_service('ryba/swarm/master'))
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker-compose.yml"
        @docker.compose.up
          header: 'Compose up without swarm'
          docker: @config.docker
          unless: (@has_service('ryba/swarm/agent') or @has_service('ryba/swarm/master'))
          services: "node_#{hosts.indexOf(@config.host)+1}"
          target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker-compose.yml"
        @then callback

## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
    builder = require 'xmlbuilder'
