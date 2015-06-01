
# Hive Server2 Wait

Wait for the RPC or HTTP ports depending on the configured transport mode.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive Server2 # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/server2', require('./index').configure
      servers = for hive_ctx in hive_ctxs
        host: hive_ctx.config.host
        port: if hive_ctx.config.ryba.hive['hive.server2.transport.mode'] is 'http'
        then hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
        else hive_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      ctx.waitIsOpen servers, next


