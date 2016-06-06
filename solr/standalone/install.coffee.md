
# Solr Install

    module.exports = header: 'Solr Standalone Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_archive_location = "/var/tmp/ryba/solr.tar.gz"
      protocol = if solr.single.ssl.enabled then 'https' else 'http'

## Dependencies

      @call once:true, 'masson/commons/java'
      @call 'masson/core/krb5_client/wait'
      @register 'write_jaas', 'ryba/lib/write_jaas'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      
## Layout

      @mkdir
        destination: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @mkdir
        directory: solr.single.conf_dir
        uid: solr.user.name
        gid: solr.group.name
      
## Users and Groups

      @group solr.group
      @user solr.user

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', timeout: -1, handler: ->          
        @call 
          if:  solr.single.source is 'HDP'
          handler: ->
            @service
              name: 'lucidworks-hdpsearch'
            @chown
              if: solr.single.source is 'HDP'
              destination: '/opt/lucidworks-hdpsearch'
              uid: solr.user.name
              gid: solr.group.name
        @call
          if: solr.single.source isnt 'HDP'
          handler: ->
            @download
              source: solr.single.source
              destination: tmp_archive_location
            @mkdir 
              destination: solr.single.install_dir
            @extract
              source: tmp_archive_location
              destination: solr.single.install_dir
              preserve_owner: false
              strip: 1
            @link 
              source: solr.single.install_dir
              destination: solr.single.latest_dir
              

      @call header: 'Configuration', handler: ->
        @link 
          source: "#{solr.single.latest_dir}/conf"
          destination: solr.single.conf_dir
        @remove
          shy: true
          destination: "#{solr.single.latest_dir}/bin/solr.in.sh"
        @link 
          source: "#{solr.single.conf_dir}/solr.in.sh"
          destination: "#{solr.single.latest_dir}/bin/solr.in.sh"
        @render
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/standalone/solr.j2"
          destination: '/etc/init.d/solr'
          local_source: true
          context: @config


## Layout

      @call header: 'Solr Layout', timeout: -1, handler: ->
        @mkdir
          destination: solr.single.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @mkdir
          destination: solr.single.log_dir
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
        if: solr.single.hdfs?
        header: 'HDFS Layout'
        destination: "/user/#{solr.user.name}"
        user: solr.user.name
        group: solr.user.name
        mode: 0o0775
        krb5_user: @config.ryba.hdfs.krb5_user

## Config
    
      @call header: 'Configure', handler: ->
        solr.single.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        solr.single.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of solr.single.auth_opts
        writes = for k,v of solr.single.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/standalone/solr.ini.sh.j2"
          destination: "#{solr.single.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local_source: true
          backup: true
          eof: true
        @render
          header: 'Solr Config'
          source: solr.single.conf_source
          destination: "#{solr.single.conf_dir}/solr.xml"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: @
          local_source: true
          backup: true
          eof: true
        @link
          source: "#{solr.single.conf_dir}/solr.xml"
          destination: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5_addprinc
        header: 'Solr Server User'
        principal: solr.single.principal
        keytab: solr.single.keytab
        randkey: true
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        
## SSL

      @java_keystore_add
        keystore: solr.single.ssl_keystore_path
        storepass: solr.single.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.single.ssl_keystore_pwd
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: solr.single.ssl_trustore_path
        storepass: solr.single.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      
## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
