
# HBase Master
[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports = ->
      'configure': [
        'ryba/hadoop/core'
        'ryba/hbase/master/configure'
      ]
      'check': [
        'ryba/hbase/master/check'
      ]
      'install': [
        'masson/core/iptables'
        'masson/core/yum'
        'masson/commons/java'
        'ryba/lib/hconfigure'
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/master/install'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hbase/master/layout'
        'ryba/hbase/master/start'
        'ryba/hbase/master/wait'
        'ryba/hbase/master/check'
      ]
      'start':[ 
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hbase/master/start'
      ]
      'stop':[
        'ryba/hbase/master/stop'
      ]
      'wait': [
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hbase/master/wait'
      ]
