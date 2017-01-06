
# Phoenix Configuration

    module.exports = ->
      {hbase} = @config.ryba
      hm_ctxs = @contexts 'ryba/hbase/master'
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      phoenix = @config.ryba.phoenix ?= {}
      phoenix.conf_dir ?= '/etc/phoenix/conf'
      # Avoid message "Class org.apache.hadoop.hbase.regionserver.LocalIndexSplitter
      # cannot be loaded Set hbase.table.sanity.checks to false at conf or table
      # descriptor if you want to bypass sanity checks"
      for hm_ctx in hm_ctxs
        hm_ctx.config.ryba.hbase.master.site['hbase.defaults.for.version.skip'] = 'true'
        hm_ctx.config.ryba.hbase.master.site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        hm_ctx.config.ryba.hbase.master.site['hbase.table.sanity.checks'] = 'true'
        hm_ctx.config.ryba.hbase.master.site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        hm_ctx.config.ryba.hbase.master.site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        hm_ctx.after
          type: 'service'
          name: 'hbase-master'
          handler: ->
            @service
              header: 'Install Phoenix'
              name: 'phoenix'
      for rs_ctx in rs_ctxs
        rs_ctx.config.ryba.hbase.rs.site['hbase.defaults.for.version.skip'] = 'true'
        rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        rs_ctx.config.ryba.hbase.rs.site['hbase.table.sanity.checks'] = 'true'
        rs_ctx.config.ryba.hbase.rs.site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        rs_ctx.config.ryba.hbase.rs.site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        rs_ctx.after
          type: 'service'
          name: 'hbase-regionserver'
          handler: ->
            @service
              header: 'Install Phoenix'
              name: 'phoenix'

## Optimisation

Set "hbase.bucketcache.ioengine" to "offheap".
