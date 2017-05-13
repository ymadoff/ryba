
# HBase Thrift server Wait

    module.exports = header: 'HBase Thrift Wait', label_true: 'READY', timeout: -1, handler: ->
      options = {}
      options.wait_http = for thrift_ctx in @contexts 'ryba/hbase/thrift'
        host: thrift_ctx.config.host
        port: thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.port']
      options.wait_http_info = for thrift_ctx in @contexts 'ryba/hbase/thrift'
        host: thrift_ctx.config.host
        port: thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.info.port']

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http

## HTTP Info Port

      @connection.wait
        header: 'HTTP Info'
        servers: options.wait_http_info
