
# HBase Thrift server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'HBase Thrift # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for thrift_ctx in @contexts 'ryba/hbase/thrift'#, require('./index').configure
          host: thrift_ctx.config.host, port: [
            thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.port']
            thrift_ctx.config.ryba.hbase.thrift.site['hbase.thrift.info.port']
          ]
