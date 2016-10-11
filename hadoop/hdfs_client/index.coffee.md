
# Hadoop HDFS Client

[Clients][hdfs_client] contact NameNode for file metadata or file modifications
and perform actual file I/O directly with the DataNodes.

[hdfs_client]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html

    module.exports =
      use:
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
      configure:
        'ryba/hadoop/hdfs_client/configure'
      commands:
        'check':
          'ryba/hadoop/hdfs_client/check'
        'install': [
          'masson/bootstrap/fs'
          'ryba/hadoop/hdfs_client/install'
          'ryba/hadoop/hdfs_client/check'
        ]
