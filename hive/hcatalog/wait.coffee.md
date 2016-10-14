
# Hive HCatalog Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.


    module.exports = header: 'Hive HCatalog Wait', timeout: -1, label_true: 'READY', handler: ->
      hive_s = @contexts 'ryba/hive/hcatalog'
      @connection.wait
        servers: for uri in hive_s[0].config.ryba.hive.hcatalog.site['hive.metastore.uris'].split ','
          {hostname, port} = url.parse uri
          host: hostname
          port: port

## Dependencies

    url = require 'url'
