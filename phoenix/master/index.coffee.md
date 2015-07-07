
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.


    module.exports = []
    module.exports.push require('../../hbase').configure

## Configuration

    module.exports.configure = (ctx) ->
      {hbase} = ctx.config.ryba
      hbase.site['hbase.defaults.for.version.skip'] ?= 'true'

These properties ensure co-location of data table and local index regions:
The local indexing feature is a technical preview and is still under
development.

      # hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.phoenix.hbase.index.balancer.IndexLoadBalancers'
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.phoenix.hbase.index.master.IndexMasterObserver'

    module.exports.push commands: 'install', modules: 'ryba/phoenix/master/install'
