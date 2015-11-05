
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('../../hbase').configure ctx
      {hbase} = ctx.config.ryba
      hbase.site['hbase.defaults.for.version.skip'] ?= 'true'
      hbase.site['phoenix.functions.allowUserDefinedFunctions'] ?= 'true'
      hbase.site['hbase.rpc.controllerfactory.class'] ?= 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
      hbase.site['hbase.regionserver.wal.codec'] ?= 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
      hbase.site['hbase.coprocessor.regionserver.classes'] ?= 'org.apache.hadoop.hbase.regionserver.LocalIndexMerger'

Factory to create the Phoenix RPC Scheduler that knows to put index updates into index queues:

      # hbase.site['hbase.region.server.rpc.scheduler.factory.class'] ?= 'org.apache.phoenix.hbase.index.ipc.PhoenixIndexRpcSchedulerFactory'
      hbase.site['hbase.region.server.rpc.scheduler.factory.class'] = null
      hbase.site['hbase.regionserver.rpc.scheduler.factory.class'] ?= 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
      hbase.site['hbase.rpc.controllerfactory.class'] ?= 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
      ctx.before
        # TODO: add header support to aspect in mecano
        type: 'service'
        name: 'hbase-regionserver'
      , ->
        @service name: 'phoenix'
        @hdp_select name: 'phoenix-client'
        @call require '../lib/hbase_enrich'
