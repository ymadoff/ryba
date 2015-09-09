
# Hive Server2 Wait

Wait for the RPC or HTTP ports depending on the configured transport mode.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive Server2 # Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for hive_ in @contexts 'ryba/hive/server2', require('./index').configure
          host: hive_.config.host
          port: if hive_.config.ryba.hive['hive.server2.transport.mode'] is 'http'
          then hive_.config.ryba.hive.site['hive.server2.thrift.http.port']
          else hive_.config.ryba.hive.site['hive.server2.thrift.port']
