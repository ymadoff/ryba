
# HBase RegionServer Wait

    module.exports = header: 'HBase RegionServer Wait', label_true: 'READY', timeout: -1, handler: ->
      options = {}
      options.wait_rpc = for rs_ctx in @contexts 'ryba/hbase/regionserver'
        host: rs_ctx.config.host
        port: rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.port']
      options.wait_info = for rs_ctx in @contexts 'ryba/hbase/regionserver'
        host: rs_ctx.config.host
        port: rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.info.port']

## RPC Port

      @connection.wait
        header: 'RPC'
        servers: options.wait_rpc

## Info Port

      @connection.wait
        header: 'Info'
        servers: options.wait_info
