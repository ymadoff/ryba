
# Hive Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive & HCat Server # Wait HCatalog', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      servers = for hive_ctx in hive_ctxs
        host: hive_ctx.config.host
        port: hive_ctx.config.ryba.hive.site['hive.metastore.uris'].split(':')[2]
      ctx.waitIsOpen servers, next

    module.exports.push name: 'Hive & HCat Server # Wait Server2', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      servers = for hive_ctx in hive_ctxs
        host: hive_ctx.config.host
        port: hive_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      ctx.waitIsOpen servers, next
