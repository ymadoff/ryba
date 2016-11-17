
# Hive Server2 Wait

Wait for the RPC or HTTP ports depending on the configured transport mode.

    module.exports = header: 'Hive Server2 Wait', timeout: -1, label_true: 'READY', handler: ->
      hive_server2 = @contexts 'ryba/hive/server2'
      @connection.wait
        servers: for hive_ in hive_server2
          host: hive_.config.host
          port: if hive_.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
          then hive_.config.ryba.hive.server2.site['hive.server2.thrift.http.port']
          else hive_.config.ryba.hive.server2.site['hive.server2.thrift.port']
