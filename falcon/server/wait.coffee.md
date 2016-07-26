
# Falcon Server Wait

Wait for the Falcon server to be started and available.

    module.exports = header: 'Falcon Server Wait', timeout: -1, label_true: 'READY', handler: ->
      falcon_ctxs = @contexts 'ryba/falcon/server', require('./configure').handler
      @wait_connect
        servers: for falcon_ctx in falcon_ctxs
          {hostname, port} = url.parse falcon_ctx.config.ryba.falcon.runtime['prism.falcon.local.endpoint']
          host: hostname
          port: port

## Dependencies

    url = require 'url'
