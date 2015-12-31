
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('../../hbase/regionserver').configure ctx
      {hbase} = ctx.config.ryba
      hbase.rs.site['hbase.defaults.for.version.skip'] = 'true'
      hbase.rs.site['phoenix.functions.allowUserDefinedFunctions'] = 'true'
      hbase.rs.site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
      hbase.rs.site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
      # Factory to create the Phoenix RPC Scheduler that knows to put index updates into index queues:
      # In [HDP 2.3.2 doc](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
      # hbase.site['hbase.region.server.rpc.scheduler.factory.class'] ?= 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
      # Historically (and worked)
      hbase.rs.site['hbase.regionserver.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
      # [Local Indexing](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
      # The local indexing feature is a technical preview and considered under development.
      # As of dec 2015, dont activate or it will prevent permission from working, displaying a message like
      # "ERROR: DISABLED: Security features are not available" after a grant 
      # hbase.site['hbase.coprocessor.regionserver.classes'] = 'org.apache.hadoop.hbase.regionserver.LocalIndexMerger'
      ctx.after
        # TODO: add header support to aspect in mecano
        type: 'service'
        name: 'hbase-regionserver'
      , ->
        @service name: 'phoenix'
        @hdp_select name: 'phoenix-client'
        @call require '../lib/hbase_enrich'
