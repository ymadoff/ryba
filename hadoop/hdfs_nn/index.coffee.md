
# Hadoop HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        ranger_admin: 'ryba/ranger/admin'
        zoo_server: module: 'ryba/zookeeper/server'
        # zkfc: 'ryba/hadoop/zkfc'
        # hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_jn: 'ryba/hadoop/hdfs_jn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
      configure: [
        'ryba/hadoop/hdfs_nn/configure'
        'ryba/ranger/plugins/hdfs/configure'
        ]
      commands:
        'backup':
          'ryba/hadoop/hdfs_nn/backup'
        'check':
          'ryba/hadoop/hdfs_nn/check'
        'install': [
          'masson/bootstrap/fs'
          'ryba/hadoop/hdfs_nn/install'
          'ryba/hadoop/hdfs_nn/start'
          'ryba/hadoop/zkfc/install'
          'ryba/hadoop/zkfc/start'
          'ryba/hadoop/hdfs_nn/layout'
          'ryba/hadoop/hdfs_nn/check'
          'ryba/ranger/plugins/hdfs/setup'
        ]
        'start':
          'ryba/hadoop/hdfs_nn/start'
        'status':
          'ryba/hadoop/hdfs_nn/status'
        'stop':
          'ryba/hadoop/hdfs_nn/stop'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
