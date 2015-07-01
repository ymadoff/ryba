# Spark Client

    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      require('../../hadoop/core').configure ctx
      require("../../hive/client").configure ctx
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      {ryba} = ctx.config
      spark = ctx.config.ryba.spark ?= {}
      spark.client_dir ?= '/usr/hdp/current/spark-client'
      spark.conf_dir ?= '/etc/spark/conf'
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/run/spark'
      spark.user.groups ?= 'hadoop'
      spark.user.gid ?= spark.group.name
      # Configuration
      spark.conf = {}
      spark.conf['spark.eventLog.enabled'] ?= "true"
      spark.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      spark.conf['spark.history.provider'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryProvider"
      spark.conf['spark.ssl.enabled'] ?= "true"
      spark.conf['spark.ssl.enabledAlgorithms'] ?= "MD5"
      spark.conf['spark.ssl.keyPassword'] ?= "ryba123"
      spark.conf['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.conf['spark.ssl.keyStorePassword'] ?= "ryba123"
      spark.conf['spark.ssl.protocol'] ?= "SSLv3"
      spark.conf['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.conf['spark.ssl.trustStorePassword'] ?= "ryba123"

## Spark History Server Configure

We set by default the address and port of the spark web ui server
Those properties are not set by default to enable user to access log trought Yarn RM WEB UI
See ryba/spark/history_server/install.coffee.md's doc for detailed information on history server.

      [shs_ctx] = ctx.contexts 'ryba/spark/history_server', require('../history_server/index').configure
      if shs_ctx
        spark.conf['spark.yarn.historyServer.address'] ?= "#{shs_ctx.config.host}:#{shs_ctx.config.ryba.spark.conf['spark.history.ui.port']}"
      else
        # HDP 2.3 sandbox set it to SHS address. If we do this here
        spark.conf['spark.yarn.historyServer.address'] ?= null

    module.exports.push commands: 'install', modules: [
      'ryba/spark/client/install'
      'ryba/spark/client/check'
    ]

    module.exports.push commands: 'check', modules: 'ryba/spark/client/check'
