
# HBase Master

[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        zoo_server: 'ryba/zookeeper/server'
        hadoop_core: 'ryba/hadoop/core'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        ranger_admin: 'ryba/ranger/admin'
        hbase_master: 'ryba/hbase/master'
        ganglia: 'ryba/ganglia/collector'
      configure: [
        'ryba/hbase/lib/configure_metrics'
        'ryba/hbase/master/configure'
        'ryba/ranger/plugins/hbase/configure'
      ]
      commands:
        'check':
          'ryba/hbase/master/check'
        'install': [
          'ryba/hbase/master/install'
          'ryba/hbase/master/layout'
          'ryba/hbase/master/start'
          'ryba/hbase/master/check'
        ]
        'start':
          'ryba/hbase/master/start'
        'stop':
          'ryba/hbase/master/stop'
