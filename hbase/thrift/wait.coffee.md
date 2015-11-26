
# HBase thrift server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'HBase Thrift # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for rs_ctx in @contexts 'ryba/hbase/thrift'#, require('./index').configure
          host: rs_ctx.config.host, port: [
            rs_ctx.config.ryba.hbase.site['hbase.thrift.port']
            rs_ctx.config.ryba.hbase.site['hbase.thrift.info.port']
          ]
