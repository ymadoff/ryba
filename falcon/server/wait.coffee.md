
# Falcon Server Wait

Wait for the Falcon server to be started and available.

    module.exports = header: 'Falcon Server Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_prism = for falcon_ctx in @contexts 'ryba/falcon/server'
        {hostname, port} = url.parse falcon_ctx.config.ryba.falcon.runtime['prism.falcon.local.endpoint']
        host: hostname
        port: port

## Prism Port

      @connection.wait
        header: 'Prism'
        servers: options.wait_prism

## Dependencies

    url = require 'url'
