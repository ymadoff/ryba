---
title: 
layout: module
---

# XASecure

    module.exports = []
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/mysql_client'

## Configuration

    module.exports.push (ctx) ->
      require('masson/commons/java').configure ctx
      require('../hadoop/hive_server').configure ctx
      require('./policymgr').configure ctx
      policymgr = ctx.host_with_module 'ryba/xasecure/policymgr'
      xasecure = ctx.config.xasecure ?= {}
      throw new Error "Required property \"xasecure.hive_url\"" unless xasecure.hive_url?
      xasecure.hive ?= {}
      xasecure.hive['POLICY_MGR_URL'] = "http://#{policymgr}:6080"
      xasecure.hive['MYSQL_CONNECTOR_JAR'] = "usr/share/java/mysql-connector-java.jar"
      # xasecure.hive['REPOSITORY_NAME'] = "vagrant_hive"
      xasecure.hive['XAAUDIT.DB.HOSTNAME'] = xasecure.policymgr['db_host']
      xasecure.hive['XAAUDIT.DB.DATABASE_NAME'] ?= xasecure.policymgr['audit_db_name']
      xasecure.hive['XAAUDIT.DB.USER_NAME'] ?= xasecure.policymgr['audit_db_user']
      xasecure.hive['XAAUDIT.DB.PASSWORD'] ?= xasecure.policymgr['audit_db_password']

    module.exports.push name: 'XASecure Hive # Install', timeout: -1, callback: (ctx, next) ->
      {hive_conf_dir} = ctx.config.hdp
      {hive} = ctx.config.xasecure
      modified = false
      source = ctx.config.xasecure.hive_url
      do_upload = ->
        u = url.parse source
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: source
          destination: '/tmp'
          binary: true
        , (err, uploaded) ->
          return next err if err
          do_extract()
      do_extract = ->
        source = "/tmp/#{path.basename source}"
        ctx.extract
          source: source
          # destination: 
        , (err) ->
          return next err if err
          do_configure()
      do_configure = ->
        # ldapsearch -x -LLL -H ldaps://noev201i.noe.edf.fr -D cn=noeyy5j8,ou=systems,dc=edfgdf,dc=fr -w d.IPQUnI -b "dc=edfgdf,dc=fr" "objectClass=*" 
        source = "#{path.dirname source}/#{path.basename source, '.tar'}"
        write = for k, v of hive
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        ctx.write
          destination: "#{source}/install.properties"
          write: write
          eof: true
        , (err, written) ->
          return next err if err
          do_install()
      do_install = ->
        ctx.execute
          cmd: "cd #{source} && ./install.sh"
          # cwd: "#{source}"
        , (err, executed) ->
          return next err if err
          do_conf()
      do_conf = ->
        # TODO, need to merge properties "hive.exec.pre.hooks", "hive.exec.post.hooks"
        ctx.hconfigure
          destination: "#{hive_conf_dir}/hive-site.xml"
          properties: 
            'hive.exec.pre.hooks': 'com.xasecure.authorization.hive.hooks.XaSecureHivePreExecuteRunHook'
            'hive.exec.post.hooks': 'com.xasecure.authorization.hive.hooks.XaSecureHivePostExecuteRunHook'
            'hive.semantic.analyzer.hook': 'com.xasecure.authorization.hive.hooks.XaSecureSemanticAnalyzerHook'
            # Overwrite com.xasecure.authentication.hive.LoginNameAuthenticator
            'hive.server2.custom.authentication.class': 'com.xasecure.authentication.hive.LoginNameAuthenticator'
            # Overwrite hive.exec.post.hooks,hive.exec.driver.run.hooks,hive.server2.authentication,hive.metastore.pre.event.listeners,hive.security.authorization.enabled,hive.security.authorization.manager,hive.semantic.analyzer.hook
            'hive.conf.restricted.list': 'hive.exec.driver.run.hooks,hive.server2.authentication,hive.metastore.pre.event.listeners,hive.security.authorization.enabled,hive.security.authorization.manager,hive.semantic.analyzer.hook,hive.exec.post.hooks'
          merge: true
        , (err, configured) ->
          return next err if err
          do_restart()
      do_restart = ->
        lifecycle.hive_metastore_restart ctx, (err) ->
          return next err if err
          lifecycle.hive_server2_restart ctx, (err) ->
            return next err if err
            next null, ctx.PASS
      do_upload()

    module.exports.push name: 'XASecure Hive # Register', timeout: -1, callback: (ctx, next) ->
      # POST http://front1.hadoop:6080/service/assets/assets
      body = 
        "name":"vagrant_hive"
        "description":"Vagrant VMs"
        "activeStatus":"1"
        "assetType":"3"
        "config":"{\"username\":\"hdfs@HADOOP.ADALTAS.COM\",\"password\":\"*****\",\"jdbc.driverClassName\":\"org.apache.hive.jdbc.HiveDriver\",\"jdbc.url\":\"jdbc:hive2://front1.hadoop:10000/default;principal=hive/front1.hadoop@HADOOP.ADALTAS.COM\",\"commonNameForCertificate\":\"\"}"
        "supportNative":false
        "userName":"hdfs@HADOOP.ADALTAS.COM"
        "passwordKeytabfile":"hdfs123"
        "driverClassName":"org.apache.hive.jdbc.HiveDriver"
        "url":"jdbc:hive2://front1.hadoop:10000/default;principal=hive/front1.hadoop@HADOOP.ADALTAS.COM"
        "commonnameforcertificate":""
        "_vPassword":""
        "fsDefaultName":""
        "authorization":""
        "authentication":""
        "auth_to_local":""
        "datanode":""
        "namenode":""
        "secNamenode":""
        "masterKerberos":""
        "rpcEngine":""
        "rpcProtection":""
        "securityAuthentication":""
        "zookeeperProperty":""
        "zookeeperQuorum":""
        "zookeeperZnodeParent":""
      next()

## Module Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'
    lifecycle = require '../hadoop/lib/lifecycle'


