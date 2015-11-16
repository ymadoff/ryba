
# Hadoop HDFS Client

[Clients](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html) contact NameNode for file metadata or file modifications and perform actual file I/O directly with the DataNodes.

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../core').configure ctx
      {ryba} = ctx.config
      ryba.hdfs.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

Since Hadoop 2.6, [SaslRpcClient](https://issues.apache.org/jira/browse/HDFS-7546) check
that targetted server principal matches configured server principal.
To configure cross-realm communication (with distcp) you need to force a bash-like pattern
to match. By default any principal ('*') will be authorized, as cross-realm trust
is already handled by kerberos

      ryba.hdfs.site['dfs.namenode.kerberos.principal.pattern'] ?= '*'

      require('../hdfs_nn').client_config ctx
      require('../hdfs_dn').client_config ctx


## Commands

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_client/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_client/install'
      'ryba/hadoop/hdfs_client/check'
    ]
