
# HBase RegionServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'HBase RegionServer # Wait', label_true: 'READY', timeout: -1, handler: (ctx, next) ->
      rs_ctxs = ctx.contexts 'ryba/hbase/regionserver', require('./index').configure
      servers = for rs_ctx in rs_ctxs
        host: rs_ctx.config.host, port: [
          rs_ctx.config.ryba.hbase.site['hbase.regionserver.port']
          rs_ctx.config.ryba.hbase.site['hbase.regionserver.info.port']
        ]
      ctx.waitIsOpen servers, next
