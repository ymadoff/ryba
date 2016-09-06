
# HBase RegionServer
[HRegionServer](http://hbase.apache.org/book.html#regionserver.arch) is the RegionServer implementation.
It is responsible for serving and managing regions. In a distributed cluster, a RegionServer runs on a DataNode.

    module.exports = ->
      'configure': [
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hbase/lib/configure_metrics'
        'ryba/hbase/regionserver/configure'
      ]
      'check':
        'ryba/hbase/regionserver/check'
      'install': [
        'masson/core/iptables'
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/regionserver/install'
        'ryba/hbase/regionserver/start'
        'ryba/hbase/regionserver/check'
      ]
      'start':
        'ryba/hbase/regionserver/start'
      'status':
        'ryba/hbase/regionserver/status'
      'stop':
        'ryba/hbase/regionserver/stop'
