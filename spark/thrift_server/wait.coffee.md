
# Spark SQL Thrift Server Wait

Wait for the ResourceManager Thrift port (HTTP and BINARY).

    module.exports = header: 'Spark SQL Thrift Server Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.thrift = for sts_ctx in @contexts 'ryba/spark/thrift_server'
        {hive_site} = sts_ctx.config.ryba.spark.thrift
        port = if hive_site['hive.server2.transport.mode'] is 'http'
        then hive_site['hive.server2.thrift.http.port']
        else hive_site['hive.server2.thrift.port']
        host: sts_ctx.config.host
        port: port

## Wait Thrift TCP/HTTP Port

      @connection.wait
        header: 'Thrift'
        servers: options.thrift
