
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports = ->
      'configure': [
        'ryba/hbase/client/configure'
      ]
      'install': [
        'ryba/hadoop/mapred_client/install' 
        'ryba/lib/hconfigure'
        'ryba/lib/write_jaas'
        'ryba/hbase/client/install'
        'ryba/hbase/master/wait'
        'ryba/hbase/client/replication'
        'ryba/hbase/client/check'
      ]
      'check': [
        'ryba/hbase/master/wait'
        'ryba/hbase/client/check'
      ]
