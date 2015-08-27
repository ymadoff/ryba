
# Hive HCatalog Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive HCatalog # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      hive_ctxs = ctx.contexts 'ryba/hive/hcatalog', require('./index').configure
      ctx.wait_connect
        servers: for uri in hive_ctxs[0].config.ryba.hive.site['hive.metastore.uris'].split ','
          {hostname, port} = url.parse uri
          host: hostname
          port: port
      .then next

## Dependencies

    url = require 'url'