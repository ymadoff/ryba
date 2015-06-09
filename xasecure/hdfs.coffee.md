
# XASecure

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/mysql_client'

## Configuration

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('../hadoop/hdfs').configure ctx # Check if still required
      require('./policymgr').configure ctx
      # require('../hadoop/core').configure ctx
      policymgr = ctx.host_with_module 'ryba/xasecure/policymgr', true
      xasecure = ctx.config.xasecure ?= {}
      throw new Error "Required property \"xasecure.hdfs_url\"" unless xasecure.hdfs_url?
      xasecure.hdfs ?= {}
      xasecure.hdfs['POLICY_MGR_URL'] = "http://#{policymgr}:6080"
      xasecure.hdfs['MYSQL_CONNECTOR_JAR'] = "/usr/share/java/mysql-connector-java.jar"
      # xasecure.hdfs['REPOSITORY_NAME'] = "vagrant_hdfs"
      xasecure.hdfs['XAAUDIT.DB.HOSTNAME'] = xasecure.policymgr['db_host']
      xasecure.hdfs['XAAUDIT.DB.DATABASE_NAME'] ?= xasecure.policymgr['audit_db_name']
      xasecure.hdfs['XAAUDIT.DB.USER_NAME'] ?= xasecure.policymgr['audit_db_user']
      xasecure.hdfs['XAAUDIT.DB.PASSWORD'] ?= xasecure.policymgr['audit_db_password']

    module.exports.push name: 'XASecure HDFS # Upload', timeout: -1, handler: (ctx, next) ->
      {hdfs_url} = ctx.config.xasecure
      do_upload = ->
        ctx[if url.parse(hdfs_url).protocol is 'http:' then 'download' else 'upload']
          source: hdfs_url
          destination: '/var/tmp'
          binary: true
          not_if_exists: "/var/tmp/#{path.basename hdfs_url, '.tar'}"
        , (err, uploaded) ->
          return next err, false if err or not uploaded
          modified = true
          do_extract()
      do_extract = ->
        ctx.extract
          source: "/var/tmp/#{path.basename hdfs_url}"
        , (err) ->
          return next err, true
      do_upload()

    module.exports.push name: 'XASecure HDFS # Configure', timeout: -1, handler: (ctx, next) ->
      {hdfs_url} = ctx.config.xasecure
      do_configure = ->
        write = for k, v of hdfs
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        ctx.write
          destination: "/var/tmp/#{path.basename hdfs_url, '.tar'}/install.properties"
          write: write
          eof: true
        , (err, written) ->
          return next err, false if err or not written
          do_install()
      do_install = ->
        ctx.execute
          cmd: "cd /var/tmp/#{path.basename hdfs_url, '.tar'} && ./install.sh"
        , (err, executed) ->
          return next err if err
          do_env()
      do_env = ->
        ctx.write
          destination: '/usr/lib/hadoop/libexec/hadoop-config.sh'
          match: /.*xasecure\-hadoop\-env\.sh.*/mg
          replace: """
          if [ -f  ${HADOOP_CONF_DIR}/xasecure-hadoop-env.sh ]; then . ${HADOOP_CONF_DIR}/xasecure-hadoop-env.sh; fi
          """
          append: true
          eof: true
        , (err, written) ->
          return next err if err
          do_restart()
      #     do_fix()
      # do_fix = ->
      #     ctx.remove
      #       destination: '/usr/lib/hadoop/lib/jersey-bundle-1.17.1.jar'
      #     , (err, removed) ->
      #       return next err if err
      #       do_restart()
      do_restart = ->
        lifecycle.nn_restart ctx, (err) ->
          return next err if err
          next err, true
      do_configure()

    module.exports.push name: 'XASecure HDFS # Fix', handler: (ctx, next) ->
      ctx.remove
        destination: '/usr/lib/hadoop/lib/jersey-bundle-1.17.1.jar'
      , next
    
    module.exports.push name: 'XASecure HDFS # Register', timeout: -1, handler: (ctx, next) ->
      # POST http://front1.hadoop:6080/service/assets/assets
      body = 
        assetType: '1'
        name: 'vagrant_hdfs'
        description: 'Vagrant VM Cluster'
        activeStatus: '1'
        config: '{"username":"hdfs@HADOOP.ADALTAS.COM","password":"hdfs123","fs.default.name":"hdfs://master1.hadoop:8020","hadoop.security.authorization":"true","hadoop.security.authentication":"kerberos","hadoop.security.auth_to_local":"RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/       RULE:[2:$1@$0](jhs@.*)s/.*/mapred/       RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/       RULE:[2:$1@$0](hm@.*)s/.*/hbase/       RULE:[2:$1@$0](rs@.*)s/.*/hbase/       DEFAULT","dfs.datanode.kerberos.principal":"dn/worker1.hadoop@HADOOP.ADALTAS.COM","dfs.namenode.kerberos.principal":"nn/master1.hadoop@HADOOP.ADALTAS.COM","dfs.secondary.namenode.kerberos.principal":"","commonNameForCertificate":""}'
        # {"username":"hdfs@HADOOP.ADALTAS.COM","password":"hdfs123","fs.default.name":"hdfs://master1.hadoop:8020","hadoop.security.authorization":"true","hadoop.security.authentication":"kerberos","hadoop.security.auth_to_local":"RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/       RULE:[2:$1@$0](jhs@.*)s/.*/mapred/       RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/       RULE:[2:$1@$0](hm@.*)s/.*/hbase/       RULE:[2:$1@$0](rs@.*)s/.*/hbase/       DEFAULT","dfs.datanode.kerberos.principal":"dn/worker1.hadoop@HADOOP.ADALTAS.COM","dfs.namenode.kerberos.principal":"nn/master1.hadoop@HADOOP.ADALTAS.COM","dfs.secondary.namenode.kerberos.principal":"","commonNameForCertificate":""}
        _vPassword: ''
        userName: 'hdfs@HADOOP.ADALTAS.COM'
        passwordKeytabfile: 'hdfs123'
        fsDefaultName: 'hdfs://master1.hadoop:8020'
        authorization: 'true'
        authentication: 'kerberos'
        auth_to_local: """
          RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
          RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
          RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
          RULE:[2:$1@$0](hm@.*)s/.*/hbase/
          RULE:[2:$1@$0](rs@.*)s/.*/hbase/
          DEFAULT
          """
        datanode: 'dn/worker1.hadoop@HADOOP.ADALTAS.COM'
        namenode: 'nn/master1.hadoop@HADOOP.ADALTAS.COM'
        secNamenode: ''
        driverClassName: ''
        url: ''
        masterKerberos: ''
        rpcEngine: ''
        rpcProtection: ''
        securityAuthentication: ''
        zookeeperProperty: ''
        zookeeperQuorum: ''
        zookeeperZnodeParent: ''
        commonnameforcertificate: ''
      next()

## Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'
    lifecycle = require '../lib/lifecycle'
      