
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.


    module.exports = ->
      'configure':[
        'ryba/phoenix/client/configure'
      ]
      'install': [
        'masson/core/yum'
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hbase/client'
        'ryba/lib/hconfigure'
        'ryba/lib/write_jaas'
        'ryba/lib/hdp_select'
        'ryba/phoenix/client/install'
        'ryba/hbase/regionserver/wait'
        'ryba/hbase/master/wait'
        'ryba/phoenix/client/init'
        'ryba/phoenix/client/check'
        ]
      'check': [
        'ryba/hbase/master/wait'
        'ryba/hbase/regionserver/wait'
        'ryba/phoenix/client/check'
        ]
