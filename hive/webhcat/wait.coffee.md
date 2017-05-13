
# WebHCat Wait

    module.exports = header: 'WebHCat Wait', timeout: -1, label_true: 'READY', handler:  ->
      options = {}
      options.wait_http = for webhcat_ctx in @contexts 'ryba/hive/webhcat'
        host: webhcat_ctx.config.host
        port: webhcat_ctx.config.ryba.webhcat.site['templeton.port']

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http

## Dependencies

    mkcmd = require '../../lib/mkcmd'
