
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
        phoenix_client: implicit: true, module: 'ryba/phoenix/client'
      configure:
        'ryba/phoenix/queryserver/configure'
      commands:
        'install': [
          'ryba/phoenix/queryserver/install'
          'ryba/phoenix/queryserver/start'
          'ryba/phoenix/queryserver/check'
        ]
        'check':
          'ryba/phoenix/queryserver/check'
        'status':
          'ryba/phoenix/queryserver/status'
        'start':
          'ryba/phoenix/queryserver/start'
        'stop':
          'ryba/phoenix/queryserver/stop'
