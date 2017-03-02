
# Solr Install

    module.exports = header: 'Solr Cloud Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_archive_location = "/var/tmp/ryba/solr.tar.gz"
      protocol = if solr.cloud.ssl.enabled then 'https' else 'http'

## Dependencies

      @call once:true, 'masson/commons/java'
      @call 'masson/core/krb5_client/wait'
      @call 'ryba/zookeeper/server/wait'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Solr Server  | 8983  | http        | port               |
| Solr Server  | 9983  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call header: 'IPTables', handler: ->
        return unless @config.iptables.action is 'start'
        @tools.iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: solr.cloud.port, protocol: 'tcp', state: 'NEW', comment: "Solr Server #{protocol}" }
          ]

## Layout

      @system.mkdir
        target: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @system.mkdir
        directory: solr.cloud.conf_dir
        uid: solr.user.name
        gid: solr.group.name

## Users and Groups

      @system.group solr.group
      @system.user solr.user

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', timeout: -1, handler: ->
        @call 
          if:  solr.cloud.source is 'HDP'
          handler: ->
            @service
              name: 'lucidworks-hdpsearch'
            @system.chown
              if: solr.cloud.source is 'HDP'
              target: '/opt/lucidworks-hdpsearch'
              uid: solr.user.name
              gid: solr.group.name
        @call
          if: solr.cloud.source isnt 'HDP'
          handler: ->
            @file.download
              source: solr.cloud.source
              target: tmp_archive_location
            @system.mkdir 
              target: solr.cloud.install_dir
            @tools.extract
              source: tmp_archive_location
              target: solr.cloud.install_dir
              preserve_owner: false
              strip: 1
            @system.link 
              source: solr.cloud.install_dir
              target: solr.cloud.latest_dir


      @call header: 'Configuration', handler: (options) ->
        @system.link 
          source: "#{solr.cloud.latest_dir}/conf"
          target: solr.cloud.conf_dir
        @system.remove
          shy: true
          target: "#{solr.cloud.latest_dir}/bin/solr.in.sh"
        @system.link 
          source: "#{solr.cloud.conf_dir}/solr.in.sh"
          target: "#{solr.cloud.latest_dir}/bin/solr.in.sh"
        @service.init
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/cloud/solr.j2"
          target: '/etc/init.d/solr'
          local: true
          context: @config
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: solr.cloud.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          perm: '0750'


## Fix scripts
The zkCli.sh file, which enable solr to communicate with zookeeper
has to be fixe to use jdk 1.8.

      @file
        header: 'Fix zKcli script'
        target: "#{solr.cloud.latest_dir}/server/scripts/cloud-scripts/zkcli.sh"
        write: [
          match: RegExp "^JVM=.*$", 'm'
          replace: "JVM=\"#{solr.cloud.jre_home}/bin/java\""
        ]
        backup: false

## Layout

      @call header: 'Solr Layout', timeout: -1, handler: ->
        @system.mkdir
          target: solr.cloud.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.mkdir
          target: solr.cloud.log_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.mkdir
          target: solr.user.home
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755


## SOLR HDFS Layout
Create HDFS solr user and its home directory

      @call 
        if: solr.cloud.hdfs?
        handler: ->
          @hdfs_mkdir
            if: @config.host is @contexts('ryba/solr/cloud')[0].config.host
            header: 'HDFS Layout'
            target: "/user/#{solr.user.name}"
            user: solr.user.name
            group: solr.user.name
            mode: 0o0775
            krb5_user: @config.ryba.hdfs.krb5_user

## Config

      @call header: 'Configure', handler: ->
        solr.cloud.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        solr.cloud.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of solr.cloud.auth_opts
        writes = for k,v of solr.cloud.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true

        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/cloud/solr.ini.sh.j2"
          target: "#{solr.cloud.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local_source: true
          backup: true
          eof: true
        @file.render
          header: 'Solr Config'
          source: "#{solr.cloud.conf_source}"
          target: "#{solr.cloud.conf_dir}/solr.xml"
          local: true
          backup: true
          eof: true
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: @config
        @system.link
          source: "#{solr.cloud.conf_dir}/solr.xml"
          target: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5.addprinc
        unless_exists: solr.cloud.spnego.keytab
        header: 'Kerberos SPNEGO'
        principal: solr.cloud.spnego.principal
        randkey: true
        keytab: solr.cloud.spnego.keytab
        uid: solr.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{solr.user.name} -c 'test -r #{solr.cloud.spnego.keytab}'"
      @krb5.addprinc
        header: 'Solr Super User'
        principal: solr.cloud.admin_principal
        password: solr.cloud.admin_password
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @file.jaas
        header: 'Solr JAAS'
        target: "#{solr.cloud.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: solr.cloud.spnego.principal
            keyTab: solr.cloud.spnego.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: solr.user.name
        gid: solr.group.name
      @krb5.addprinc
        header: 'Solr Server User'
        principal: solr.cloud.principal
        keytab: solr.cloud.keytab
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Bootstrap Zookeeper

      @system.execute
        header: 'Zookeeper bootstrap'
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zkhosts} \ 
          -cmd bootstrap -solrhome #{solr.user.home}
        """
        unless_exec: "zookeeper-client -server #{solr.cloud.zk_connect} ls /#{solr.cloud.zk_node} | grep '#{solr.cloud.zk_node}'"

## Enable Authentication and ACLs
For now we skip security configuration to solr when source is 'HDP'.
HDP has version 5.2.1 of solr, and security plugins are included from 5.3.0

      @system.execute
        header: "Upload Security conf"
        if: (@contexts('ryba/solr/cloud')[0].config.host is @config.host)
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zk_connect} \
          -cmd put /solr/security.json '#{JSON.stringify solr.cloud.security}'
        """

## SSL

      @java.keystore_add
        keystore: solr.cloud.ssl_keystore_path
        storepass: solr.cloud.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.cloud.ssl_keystore_pwd
        name: @config.shortname
        local_source: true
      @java.keystore_add
        keystore: solr.cloud.ssl_trustore_path
        storepass: solr.cloud.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # not documented but needed when SSL
      @system.execute
        header: "Enable SSL Scheme"
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zkhosts} \
          -cmd clusterprop -name urlScheme -val #{protocol}
        """

## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
