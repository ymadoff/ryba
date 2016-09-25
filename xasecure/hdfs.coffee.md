
# XASecure

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/mysql/client'

## Configuration

    module.exports.configure = (ctx) ->
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

    module.exports.push header: 'XASecure HDFS # Upload', timeout: -1, handler: ->
      {hdfs_url} = ctx.config.xasecure
      @file.download
        source: hdfs_url
        target: '/var/tmp'
        binary: true
        unless_exists: "/var/tmp/#{path.basename hdfs_url, '.tar'}"
      @extract
        source: "/var/tmp/#{path.basename hdfs_url}"
        if: -> @status -1

    module.exports.push header: 'XASecure HDFS # Configure', timeout: -1, handler: ->
      {hdfs_url} = @config.xasecure
      @file
        target: "/var/tmp/#{path.basename hdfs_url, '.tar'}/install.properties"
        write: for k, v of hdfs
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        eof: true
      @execute
        cmd: "cd /var/tmp/#{path.basename hdfs_url, '.tar'} && ./install.sh"
      @file
        target: '/usr/lib/hadoop/libexec/hadoop-config.sh'
        match: /.*xasecure\-hadoop\-env\.sh.*/mg
        replace: """
        if [ -f  ${HADOOP_CONF_DIR}/xasecure-hadoop-env.sh ]; then . ${HADOOP_CONF_DIR}/xasecure-hadoop-env.sh; fi
        """
        append: true
        eof: true
      @service
        name: 'hadoop-hfds-namenode'
        action: 'restart'

    module.exports.push header: 'XASecure HDFS # Fix', handler: ->
      @remove
        target: '/usr/lib/hadoop/lib/jersey-bundle-1.17.1.jar'

    module.exports.push header: 'XASecure HDFS # Register', timeout: -1, handler: ->
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

## Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'
    lifecycle = require '../lib/lifecycle'
