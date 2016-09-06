
# HBase Master

[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports = ->
      'configure': [
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hbase/lib/configure_metrics'
        'ryba/hbase/master/configure'
      ]
      'check':
        'ryba/hbase/master/check'
      'install': [
        'masson/core/iptables'
        'masson/core/yum'
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/master/install'
        'ryba/hbase/master/layout'
        'ryba/hbase/master/start'
        'ryba/hbase/master/check'
      ]
      'start':
        'ryba/hbase/master/start'
      'stop':
        'ryba/hbase/master/stop'
