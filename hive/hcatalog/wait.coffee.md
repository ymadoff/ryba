
# Hive HCatalog Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.


    module.exports = header: 'Hive HCatalog Wait', timeout: -1, label_true: 'READY', handler: ->
      hive_ctxs = @contexts 'ryba/hive/hcatalog'
      options = {}
      options.wait_rpc = for hive_ctx in hive_ctxs
        host: hive_ctx.config.host
        port: hive_ctx.config.ryba.hive.hcatalog.site['hive.metastore.port']

## RCP

The Hive metastore listener port, default to "9083".

      @connection.wait
        header: 'RPC'
        servers: options.wait_rpc

## Dependencies

    url = require 'url'
