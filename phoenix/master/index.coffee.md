
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
      # Local indexing
      hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.phoenix.hbase.index.balancer.IndexLoadBalancer'
      hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.phoenix.hbase.index.master.IndexMasterObserver'
      ctx.before
        # TODO: add header support to aspect in mecano
        type: 'service'
        name: 'hbase-master'
      , ->
        @service name: 'phoenix'
        @hdp_select name: 'phoenix-client'
        @call require '../lib/hbase_enrich'

These properties ensure co-location of data table and local index regions:
The local indexing feature is a technical preview and is still under
development.

      # hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.phoenix.hbase.index.balancer.IndexLoadBalancers'
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.phoenix.hbase.index.master.IndexMasterObserver'
