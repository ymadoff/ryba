
# HBase RegionServer Wait

    module.exports = header: 'HBase RegionServer Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for rs_ctx in @contexts 'ryba/hbase/regionserver'
          host: rs_ctx.config.host, port: [
            rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.port']
            rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.info.port']
          ]
