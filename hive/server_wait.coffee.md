
# Hive Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive & HCat Server # Wait HCatalog', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      hive_ctx = hive_ctxs[0]
      uris = hive_ctx.config.ryba.hive.site['hive.metastore.uris'].split ','
      servers = for uri in uris
        {hostname, port} = url.parse uri
        host: hostname
        port: port
      ctx.waitIsOpen servers, next

    module.exports.push name: 'Hive & HCat Server # Wait Server2', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      servers = for hive_ctx in hive_ctxs
        host: hive_ctx.config.host
        port: if hive_ctx.config.ryba.hive['hive.server2.transport.mode'] is 'http'
        then hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
        else hive_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      ctx.waitIsOpen servers, next

## Dependencies

    url = require 'url'