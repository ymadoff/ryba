
# Hadoop HDFS Client Configure

    module.exports = ->
      [nn_ctx] = @contexts 'ryba/hadoop/hdfs_nn'
      [dn_ctx] = @contexts 'ryba/hadoop/hdfs_dn'
      hdfs = @config.ryba.hdfs ?= {}
      hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY'

Since Hadoop 2.6, [SaslRpcClient](https://issues.apache.org/jira/browse/HDFS-7546) check
that targetted server principal matches configured server principal.
To configure cross-realm communication (with distcp) you need to force a bash-like pattern
to match. By default any principal ('*') will be authorized, as cross-realm trust
is already handled by kerberos

      hdfs.site['dfs.namenode.kerberos.principal.pattern'] ?= '*'

## Import NameNode properties

      for property in [
        'dfs.namenode.kerberos.principal'
        'dfs.namenode.kerberos.internal.spnego.principal'
        'dfs.namenode.kerberos.https.principal'
        'dfs.web.authentication.kerberos.principal'
        'dfs.ha.automatic-failover.enabled'
        'dfs.nameservices'
        'dfs.internal.nameservices'
        'fs.permissions.umask-mode'
      ] then hdfs.site[property] ?= nn_ctx.config.ryba.hdfs.nn.site[property]
      for property of nn_ctx.config.ryba.hdfs.nn.site
        ok = false
        ok = true if /^dfs\.namenode\.\w+-address/.test property
        ok = true if property.indexOf('dfs.client.failover.proxy.provider.') is 0
        ok = true if property.indexOf('dfs.ha.namenodes.') is 0
        continue unless ok
        hdfs.site[property] ?= nn_ctx.config.ryba.hdfs.nn.site[property]

## Import DataNode properties

      for property in [
        'dfs.datanode.kerberos.principal'
        'dfs.client.read.shortcircuit'
        'dfs.domain.socket.path'
      ] then hdfs.site[property] ?= dn_ctx.config.ryba.hdfs.site[property]
