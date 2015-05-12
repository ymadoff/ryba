
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.


    module.exports = []
    module.exports.push require('../hbase').configure

## Configuration

    module.exports.configure = (ctx) ->
      {hbase} = ctx.config.ryba
      hbase.site['hbase.defaults.for.version.skip'] ?= 'true'
      hbase.site['hbase.regionserver.wal.codec'] ?= 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'

Factory to create the Phoenix RPC Scheduler that knows to put index updates into index queues:

      hbase.site['hbase.region.server.rpc.scheduler.factory.class'] ?= 'org.apache.phoenix.hbase.index.ipc.PhoenixIndexRpcSchedulerFactory'

These properties ensure co-location of data table and local index regions:
The local indexing feature is a technical preview and considered under development.

      # hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.phoenix.hbase.index.balancer.IndexLoadBalancers'
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.phoenix.hbase.index.master.IndexMasterObserver'


## Commands

    module.exports.push commands: 'check', modules: 'ryba/phoenix/check'

    module.exports.push commands: 'install', modules: 'ryba/phoenix/install'
