
# HBase RegionServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'HBase RegionServer # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for rs_ctx in @contexts 'ryba/hbase/regionserver'#, require('./index').configure
          host: rs_ctx.config.host, port: [
            rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.port']
            rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.info.port']
          ]
