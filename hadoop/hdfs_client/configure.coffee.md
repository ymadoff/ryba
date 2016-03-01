
# Hadoop HDFS Client Configure

    module.exports = handler: ->
      hdfs = @config.ryba.hdfs ?= {}
      hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY'

Since Hadoop 2.6, [SaslRpcClient](https://issues.apache.org/jira/browse/HDFS-7546) check
that targetted server principal matches configured server principal.
To configure cross-realm communication (with distcp) you need to force a bash-like pattern
to match. By default any principal ('*') will be authorized, as cross-realm trust
is already handled by kerberos

      hdfs.site['dfs.namenode.kerberos.principal.pattern'] ?= '*'
      require('../hdfs_nn/configure').client_config.call @
      require('../hdfs_dn/configure').client_config.call @
