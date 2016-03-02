
# HBase Thrift server Wait

    module.exports = header: 'HBase Thrift Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for thrift_ctx in @contexts 'ryba/hbase/thrift'
          host: thrift_ctx.config.host, port: [
            thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.port']
            thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.info.port']
          ]
