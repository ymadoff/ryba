
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.


    module.exports = []
    # module.exports.push require('../../hbase').configure

## Configuration

    module.exports.configure = (ctx) ->
      {hbase} = ctx.config.ryba
      phoenix = ctx.config.ryba.phoenix ?= {}
      phoenix.conf_dir ?= '/etc/phoenix/conf'

## Commands

    module.exports.push commands: 'check', modules: 'ryba/phoenix/client/check'

    module.exports.push commands: 'install', modules: [
      'ryba/phoenix/client/install'
      'ryba/phoenix/client/check'
    ]

## Optimisation

Set "hbase.bucketcache.ioengine" to "offheap".
