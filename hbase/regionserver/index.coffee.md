
# HBase RegionServer
[HRegionServer](http://hbase.apache.org/book.html#regionserver.arch) is the RegionServer implementation.
It is responsible for serving and managing regions. In a distributed cluster, a RegionServer runs on a DataNode.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core'
        'ryba/hbase/regionserver/configure'
      ]
      'check': [
        'ryba/hbase/regionserver/check'
      ]
      'install': [
        'masson/core/iptables'
        'masson/commons/java'
        'ryba/lib/hconfigure'
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/regionserver/install'
        'ryba/hbase/master/wait'
        'ryba/hbase/regionserver/start'
        'ryba/hbase/regionserver/wait'
        'ryba/hbase/regionserver/check'
      ]
      'start':[
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/start'
        'ryba/hbase/master/wait'
        'ryba/hbase/regionserver/start'
      ]
      'status':
        'ryba/hbase/regionserver/status'
      'stop':
        'ryba/hbase/regionserver/stop'
