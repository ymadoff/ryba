
# Hadoop HDFS Client

[Clients](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html) contact NameNode for file metadata or file modifications and perform actual file I/O directly with the DataNodes.

    module.exports = []

    module.exports.configure = (ctx) ->
      console.log 'hdfs_client'
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      ryba.hdfs.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
      require('./hdfs_nn').client_config ctx
      require('./hdfs_dn').client_config ctx


## Commands

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_client_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_client_install'
      'ryba/hadoop/hdfs_client_check'
    ]
