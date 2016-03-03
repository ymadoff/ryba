
# Oozie Server Wait

Run the command `./bin/ryba status -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = header: 'Oozie Server Wait', timeout: -1, label_true: 'READY', handler: ->
      os_ctxs = @contexts 'ryba/oozie/server'

## Wait TCP
      
      @wait_connect
        servers: for os_ctx in os_ctxs
          {hostname, port} = url.parse os_ctx.config.ryba.oozie.site['oozie.base.url']
          host: hostname, port: port

## Dependencies

    url = require 'url'
