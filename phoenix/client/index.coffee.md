
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hbase_master: 'ryba/hbase/master'
        hbase_rs: 'ryba/hbase/regionserver'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/phoenix/client/configure'
      commands:
        'install': [
          'ryba/phoenix/client/install'
          'ryba/phoenix/client/init'
          'ryba/phoenix/client/check'
        ]
        'check':
          'ryba/phoenix/client/check'
