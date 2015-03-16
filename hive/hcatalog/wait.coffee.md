
# Hive HCatalog Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive HCatalog # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/hcatalog', require('./index').configure
      hive_ctx = hive_ctxs[0]
      uris = hive_ctx.config.ryba.hive.site['hive.metastore.uris'].split ','
      servers = for uri in uris
        {hostname, port} = url.parse uri
        host: hostname
        port: port
      ctx.waitIsOpen servers, next

## Dependencies

    url = require 'url'