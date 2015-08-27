
# Oozie Server Wait

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait TCP

    module.exports.push name: 'HDFS NN # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      os_ctxs = ctx.contexts 'ryba/oozie/server', require('./index').configure
      ctx.wait_connect
        servers: for os_ctx in os_ctxs
          {hostname, port} = url.parse os_ctx.config.ryba.oozie.site['oozie.base.url']
          host: hostname, port: port
      .then next

## Dependencies


    url = require 'url'
