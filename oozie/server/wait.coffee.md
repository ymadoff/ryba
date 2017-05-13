
# Oozie Server Wait

Run the command `./bin/ryba status -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = header: 'Oozie Server Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.http = for oozie_ctx in @contexts 'ryba/oozie/server'
        {hostname, port} = url.parse oozie_ctx.config.ryba.oozie.site['oozie.base.url']
        host: hostname, port: port

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http

## Dependencies

    url = require 'url'
