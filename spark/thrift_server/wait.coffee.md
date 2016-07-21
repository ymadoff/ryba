
# Spark SQL Thrift Server Wait

Wait for the ResourceManager Thrift port (HTTP and BINARY).

    module.exports = header: 'Spark SQL Thrift Server Wait', timeout: -1, label_true: 'READY', handler: ->
      sts_ctxs = @contexts modules: 'ryba/spark/thrift_server'

      for sts_ctx in sts_ctxs
        {hive_site} = sts_ctx.config.ryba.spark.thrift
        port = if hive_site['hive.server2.transport.mode'] is 'http'
        then hive_site['hive.server2.thrift.http.port']
        else hive_site['hive.server2.thrift.port']
        @wait_connect
          host: sts_ctx.config.host
          port: port
