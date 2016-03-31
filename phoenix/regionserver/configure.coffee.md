## Configuration

    module.exports = handler: ->
      rs_ctxs = @contexts 'ryba/hbase/regionserver', require('../../hbase/regionserver/configure').handler
      for rs_ctx in rs_ctxs
        rs_ctx.config.ryba.hbase.rs.site['hbase.defaults.for.version.skip'] = 'true'
        rs_ctx.config.ryba.hbase.rs.site['phoenix.functions.allowUserDefinedFunctions'] = 'true'
        rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        rs_ctx.config.ryba.hbase.rs.site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        # Factory to create the Phoenix RPC Scheduler that knows to put index updates into index queues:
        # In [HDP 2.3.2 doc](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
        # hbase.site['hbase.region.server.rpc.scheduler.factory.class'] ?= 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        # Historically (and worked)
        rs_ctx.config.ryba.hbase.rs.site['hbase.regionserver.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        # [Local Indexing](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
        # The local indexing feature is a technical preview and considered under development.
        # As of dec 2015, dont activate or it will prevent permission from working, displaying a message like
        # "ERROR: DISABLED: Security features are not available" after a grant 
        # hbase.site['hbase.coprocessor.regionserver.classes'] = 'org.apache.hadoop.hbase.regionserver.LocalIndexMerger'
      @after
        # TODO: add header support to aspect in mecano
        type: 'service'
        name: 'hbase-regionserver'
      , ->
        @service name: 'phoenix'
        @hdp_select name: 'phoenix-client'
        @call require '../lib/hbase_enrich'
