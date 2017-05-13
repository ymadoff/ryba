
# HBase Rest server Wait

    module.exports = header: 'HBase Rest Wait', label_true: 'READY', timeout: -1, handler: ->
      options = {}
      options.wait_http = for rest_ctx in @contexts 'ryba/hbase/rest'
        host: rest_ctx.config.host
        port: rest_ctx.config.ryba.hbase.rest.site['hbase.rest.port']
      options.wait_http_info = for rest_ctx in @contexts 'ryba/hbase/rest'
        host: rest_ctx.config.host
        port: rest_ctx.config.ryba.hbase.rest.site['hbase.rest.info.port']

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http

## HTTP Info Port

      @connection.wait
        header: 'HTTP Info'
        servers: options.wait_http_info
