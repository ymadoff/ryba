
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
      @register 'write_jaas', 'ryba/lib/write_jaas'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      
## Layout

      @mkdir
        destination: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @mkdir
        directory: solr.cloud.conf_dir
        uid: solr.user.name
        gid: solr.group.name
      
## Users and Groups

      @group solr.group
      @user solr.user

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', timeout: -1, handler: ->          
        @call 
          if:  solr.cloud.source is 'HDP'
          handler: ->
            @service
              name: 'lucidworks-hdpsearch'
            @chown
              if: solr.cloud.source is 'HDP'
              destination: '/opt/lucidworks-hdpsearch'
              uid: solr.user.name
              gid: solr.group.name
        @call
          if: solr.cloud.source isnt 'HDP'
          handler: ->
            @download
              source: solr.cloud.source
              destination: tmp_archive_location
            @mkdir 
              destination: solr.cloud.install_dir
            @extract
              source: tmp_archive_location
              destination: solr.cloud.install_dir
              preserve_owner: false
              strip: 1
            @link 
              source: solr.cloud.install_dir
              destination: solr.cloud.latest_dir
              

      @call header: 'Configuration', handler: ->
        @link 
          source: "#{solr.cloud.latest_dir}/conf"
          destination: solr.cloud.conf_dir
        @remove
          shy: true
          destination: "#{solr.cloud.latest_dir}/bin/solr.in.sh"
        @link 
          source: "#{solr.cloud.conf_dir}/solr.in.sh"
          destination: "#{solr.cloud.latest_dir}/bin/solr.in.sh"
        @render
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/cloud/solr.j2"
          destination: '/etc/init.d/solr'
          local_source: true
          context: @config


## Fix scripts
The zkCli.sh file, which enable solr to communicate with zookeeper
has to be fixe to use jdk 1.8.

      @write
        header: 'Fix zKcli script'
        destination: "#{solr.cloud.latest_dir}/server/scripts/cloud-scripts/zkcli.sh"
        write: [
          match: RegExp "^JVM=.*$", 'm'
          replace: "JVM=\"#{solr.cloud.jre_home}/bin/java\""
        ]
        backup: false

## Layout

      @call header: 'Solr Layout', timeout: -1, handler: ->
        @mkdir
          destination: solr.cloud.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @mkdir
          destination: solr.cloud.log_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @mkdir
          destination: solr.user.home
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        

## SOLR HDFS Layout
Create HDFS solr user and its home directory

      @hdfs_mkdir
        if: solr.cloud.hdfs?
        if: @config.host is @contexts('ryba/solr/cloud')[0].config.host
        header: 'HDFS Layout'
        destination: "/user/#{solr.user.name}"
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
        @render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/cloud/solr.ini.sh.j2"
          destination: "#{solr.cloud.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local_source: true
          backup: true
          eof: true
        @render
          header: 'Solr Config'
          source: solr.cloud.conf_source
          destination: "#{solr.cloud.conf_dir}/solr.xml"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: @
          local_source: true
          backup: true
          eof: true
        @link
          source: "#{solr.cloud.conf_dir}/solr.xml"
          destination: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5_addprinc
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
      @execute
        header: 'SPNEGO'
        cmd: "su -l #{solr.user.name} -c 'test -r #{solr.cloud.spnego.keytab}'"
      @krb5_addprinc
        header: 'Solr Super User'
        principal: solr.cloud.admin_principal
        password: solr.cloud.admin_password
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        header: 'Solr JAAS'
        destination: "#{solr.cloud.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: solr.cloud.spnego.principal
            keyTab: solr.cloud.spnego.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: solr.user.name
        gid: solr.group.name
      @krb5_addprinc
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
    
      @execute
        header: 'Zookeeper bootstrap'
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zkhosts} \ 
          -cmd bootstrap -solrhome #{solr.user.home}
        """
        unless_exec: "zookeeper-client -server #{solr.cloud.zk_connect} ls / | grep solr"

## Enable Authentication and ACLs
For now we skip security configuration to solr when source is 'HDP'.
HDP has version 5.2.1 of solr, and security plugins are included from 5.3.0

      @execute
        header: "Upload Security conf"
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zk_connect} \
          -cmd put /solr/security.json '#{JSON.stringify solr.cloud.security}'
        """
        
## SSL

      @java_keystore_add
        keystore: solr.cloud.ssl_keystore_path
        storepass: solr.cloud.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.cloud.ssl_keystore_pwd
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: solr.cloud.ssl_trustore_path
        storepass: solr.cloud.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # not documented but needed when SSL
      @execute
        header: "Enable SSL Scheme"
        cmd: """
          cd #{solr.cloud.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.cloud.zkhosts} \
          -cmd clusterprop -name urlScheme -val #{protocol}
        """
      
## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
