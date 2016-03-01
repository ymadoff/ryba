
# Hadoop HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports = ->
      'backup':
        'ryba/hadoop/hdfs_nn/backup'
      'check': [
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hadoop/hdfs_nn/check'
      ]
      'configure': [
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_nn/configure'
      ]
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/hdfs_jn/wait'
        'ryba/hadoop/hdfs_nn/install'
        'ryba/hadoop/hdfs_nn/start'
        'ryba/hadoop/zkfc/install'
        'ryba/hadoop/zkfc/start'
        'ryba/hadoop/hdfs_dn/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hadoop/hdfs_nn/layout'
        'ryba/hadoop/hdfs_nn/check'
      ]
      'start': [
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_jn/wait'
        'ryba/hadoop/hdfs_nn/start'
        'ryba/hadoop/hdfs_nn/wait'
      ]
      'status':
        'ryba/hadoop/hdfs_nn/status'
      'stop':
        'ryba/hadoop/hdfs_nn/stop'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
