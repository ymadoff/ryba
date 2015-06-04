# Spark History Server 

      
    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      require('../../../ryba/hadoop/core').configure ctx
      require('../client/index').configure ctx
      {ryba} = ctx.config
      spark = ryba.spark ?= {}
      spark.user ?= {}
      spark.history_server.isKerberos = true
      
      #history_server = spark.history_server ?= {}
      #history_server.fqdn = "master2.ryba"
      #history_server.port = "8190"
      #spark.ui= "18080"
      #history_server.isKerberos = "true"
      
      
    module.exports.push commands: 'install', modules: [
      'ryba/spark/history_server/install'
      'ryba/spark/history_server/status'
    ]
    module.exports.push commands: 'status', modules: [
      'ryba/spark/history_server/status'
    ]
    module.exports.push commands: 'start', modules: [
      'ryba/spark/history_server/start'
      'ryba/spark/history_server/status'

    ]
    module.exports.push commands: 'stop', modules: [
      'ryba/spark/history_server/stop'
    ]
