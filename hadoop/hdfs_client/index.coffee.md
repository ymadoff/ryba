
# Hadoop HDFS Client

[Clients][hdfs_client] contact NameNode for file metadata or file modifications
and perform actual file I/O directly with the DataNodes.

[hdfs_client]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html

    module.exports = ->
      'check': [
        'ryba/hadoop/hdfs_client/check'
      ]
      'configure': [
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_client/configure'
      ]
      'install': [
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_client/install'
        'ryba/hadoop/hdfs_client/check'
      ]
