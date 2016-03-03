
# WebHCat Wait

    module.exports = header: 'WebHCat Wait', timeout: -1, label_true: 'READY', handler:  ->
      webhcat_ctxs = @contexts 'ryba/hive/webhcat'
      @wait_connect
        servers: for webhcat_ctx in webhcat_ctxs
          host: webhcat_ctx.config.host, port: webhcat_ctx.config.ryba.webhcat.site['templeton.port']

## Dependencies

    mkcmd = require '../../lib/mkcmd'
