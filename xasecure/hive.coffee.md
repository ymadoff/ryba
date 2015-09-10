
# XASecure

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push require '../lib/hconfigure'

## Configuration

    module.exports.push (ctx) ->
      require('masson/commons/java').configure ctx
      require('../hive/server').configure ctx
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

    module.exports.push name: 'XASecure HDFS # Upload', timeout: -1, handler: ->
      {hive_url} = ctx.config.xasecure
      @download
        source: hive_url
        destination: '/var/tmp'
        binary: true
        not_if_exists: "/var/tmp/#{path.basename hive_url, '.tar'}"
      @extract
        source: "/var/tmp/#{path.basename hive_url}"
        if: -> @status -1

    module.exports.push name: 'XASecure Hive # Install', timeout: -1, handler: ->
      {conf_dir} = ctx.config.ryba.hive
      {hive, hive_url} = ctx.config.xasecure
      @write
        destination: "/var/tmp/#{path.basename hive_url, '.tar'}/install.properties"
        write: for k, v of hive
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        eof: true
      @execute
        cmd: "cd /var/tmp/#{path.basename hive_url, '.tar'} && ./install.sh"
      # TODO, need to merge properties "hive.exec.pre.hooks", "hive.exec.post.hooks"
      @hconfigure
        destination: "#{conf_dir}/hive-site.xml"
        properties: 
          'hive.exec.pre.hooks': 'com.xasecure.authorization.hive.hooks.XaSecureHivePreExecuteRunHook'
          'hive.exec.post.hooks': 'com.xasecure.authorization.hive.hooks.XaSecureHivePostExecuteRunHook'
          'hive.semantic.analyzer.hook': 'com.xasecure.authorization.hive.hooks.XaSecureSemanticAnalyzerHook'
          # Overwrite com.xasecure.authentication.hive.LoginNameAuthenticator
          'hive.server2.custom.authentication.class': 'com.xasecure.authentication.hive.LoginNameAuthenticator'
          # Overwrite hive.exec.post.hooks,hive.exec.driver.run.hooks,hive.server2.authentication,hive.metastore.pre.event.listeners,hive.security.authorization.enabled,hive.security.authorization.manager,hive.semantic.analyzer.hook
          'hive.conf.restricted.list': 'hive.exec.driver.run.hooks,hive.server2.authentication,hive.metastore.pre.event.listeners,hive.security.authorization.enabled,hive.security.authorization.manager,hive.semantic.analyzer.hook,hive.exec.post.hooks'
        merge: true
      @service
        name: 'hive-hcatalog-server'
        action: 'restart'
      @service
        name: 'hive-server2'
        action: 'restart'

    module.exports.push name: 'XASecure Hive # Register', timeout: -1, handler: ->
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
        "url":"jdbc:hive2://front1.hadoop:10001/default;principal=hive/front1.hadoop@HADOOP.ADALTAS.COM"
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

## Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'
    lifecycle = require '../lib/lifecycle'
