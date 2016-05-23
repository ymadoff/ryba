
# Solr Install

    module.exports = header: 'Solr Cloud Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_archive_location = "/var/tmp/ryba/solr.tar.gz"
      protocol = if solr.ssl.enabled then 'https' else 'http'

## Dependencies

      @call once:true, 'masson/commons/java'
      @call 'masson/core/krb5_client/wait'
      @call 'ryba/zookeeper/server/wait'
      @register 'write_jaas', 'ryba/lib/write_jaas'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      
## Users and Groups

      @group solr.group
      @user solr.user

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', timeout: -1, handler: ->          
        @call 
          if:  solr.source is 'HDP'
          handler: ->
            @service
              name: 'lucidworks-hdpsearch'
            @chown
              if: solr.source is 'HDP'
              destination: '/opt/lucidworks-hdpsearch'
              uid: solr.user.name
              gid: solr.group.name
        @call
          if: solr.source isnt 'HDP'
          handler: ->
            @download
              source: solr.source
              destination: tmp_archive_location
            @mkdir 
              destination: solr.install_dir
            @extract
              source: tmp_archive_location
              destination: solr.install_dir
              preserve_owner: false
              strip: 1
            @link 
              source: solr.install_dir
              destination: solr.latest_dir
              

      @call header: 'Layout', handler: ->
        @mkdir
          destination: solr.user.home
          uid: solr.user.name
          gid: solr.group.name
        @mkdir
          directory: solr.conf_dir
          uid: solr.user.name
          gid: solr.group.name
        @link 
          source: "#{solr.latest_dir}/conf"
          destination: solr.conf_dir
        @remove
          shy: true
          destination: "#{solr.latest_dir}/bin/solr.in.sh"
        @link 
          source: "#{solr.conf_dir}/solr.in.sh"
          destination: "#{solr.latest_dir}/bin/solr.in.sh"
        @render
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/solr.j2"
          destination: '/etc/init.d/solr'
          local_source: true
          context: @config


## Fix scripts
The zkCli.sh file, which enable solr to communicate with zookeeper
has to be fixe to use jdk 1.8.

      @write
        header: 'Fix zKcli script'
        destination: "#{solr.latest_dir}/server/scripts/cloud-scripts/zkcli.sh"
        write: [
          match: RegExp "^JVM=.*$", 'm'
          replace: "JVM=\"#{solr.jre_home}/bin/java\""
        ]
        backup: false

## Layout

      @call header: 'Solr Layout', timeout: -1, handler: ->
        @mkdir
          destination: solr.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @mkdir
          destination: solr.log_dir
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
        if: solr.hdfs?
        header: 'HDFS Layout'
        destination: "/user/#{solr.user.name}"
        user: solr.user.name
        group: solr.user.name
        mode: 0o0775
        krb5_user: @config.ryba.hdfs.krb5_user

## Config
    
      @call header: 'Configure', handler: ->
        solr.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        solr.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of solr.auth_opts
        writes = for k,v of solr.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/solr.ini.sh.j2"
          destination: "#{solr.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local_source: true
          backup: true
          eof: true
        @render
          header: 'Solr Config'
          source: solr.conf_source
          destination: "#{solr.conf_dir}/solr.xml"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: @
          local_source: true
          backup: true
          eof: true
        @link
          source: "#{solr.conf_dir}/solr.xml"
          destination: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5_addprinc
        header: 'Kerberos SPNEGO'
        principal: solr.spnego.principal
        randkey: true
        keytab: solr.spnego.keytab
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @krb5_addprinc
        header: 'Solr Super User'
        principal: solr.admin_principal
        password: solr.admin_password
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        header: 'Solr JAAS'
        destination: "#{solr.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: solr.spnego.principal
            keyTab: solr.spnego.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: solr.user.name
        gid: solr.group.name
      @krb5_addprinc
        header: 'Solr Server User'
        principal: solr.principal
        keytab: solr.keytab
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
          cd #{solr.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.zkhosts} \ 
          -cmd bootstrap -solrhome #{solr.user.home}
        """
        unless_exec: "zookeeper-client -server #{solr.zk_connect} ls / | grep solr"

## Enable Authentication and ACLs
For now we skip security configuration to solr when source is 'HDP'.
HDP has version 5.2.1 of solr, and security plugins are included from 5.3.0

      @execute
        
        header: "Upload Security conf"
        cmd: """
          cd #{solr.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.zk_connect} \
          -cmd put /solr/security.json '#{JSON.stringify solr.security}'
        """
      
## SSL

      @java_keystore_add
        keystore: solr.ssl_keystore_path
        storepass: solr.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.ssl_keystore_pwd
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: solr.ssl_trustore_path
        storepass: solr.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # not documented but needed when SSL
      @execute
        header: "Enable SSL Scheme"
        cmd: """
          cd #{solr.latest_dir}
          server/scripts/cloud-scripts/zkcli.sh -zkhost #{solr.zkhosts} \
          -cmd clusterprop -name urlScheme -val #{protocol}
        """
        
## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
