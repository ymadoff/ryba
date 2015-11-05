
# Hive HCatalog Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'Hive HCatalog # Wait', timeout: -1, label_true: 'READY', handler: ->
      hive_s = @contexts 'ryba/hive/hcatalog', require('./index').configure
      @wait_connect
        servers: for uri in hive_s[0].config.ryba.hive.site['hive.metastore.uris'].split ','
          {hostname, port} = url.parse uri
          host: hostname
          port: port

## Dependencies

    url = require 'url'
