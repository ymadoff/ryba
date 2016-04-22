
# Spark SQL Thrift Server Wait

Wait for the Spark SQL Thrift Server port (HTTP or BINARY).

    module.exports = header: 'Spark SQL Thrift Server Wait', timeout: -1, label_true: 'READY', handler: ->
      {hive_site} = @config.ryba.spark.thrift
      port = if hive_site['hive.server2.transport.mode'] is 'http'
      then hive_site['hive.server2.thrift.http.port']
      else hive_site['hive.server2.thrift.port']
      @call once:true, 'ryba/spark/thrift_server/wait'
      @wait_connect
        host: @config.host
        port: port
