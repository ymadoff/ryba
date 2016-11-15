
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        mapred_client: 'ryba/hadoop/mapred_client'
      configure:
        'ryba/hbase/client/configure'
      commands:
        'install': [
          # 
          'ryba/hbase/client/install'
          'ryba/hbase/client/replication'
          'ryba/hbase/client/check'
        ]
        'check':
          'ryba/hbase/client/check'
