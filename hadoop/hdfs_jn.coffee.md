
# Hadoop HDFS JournalNode

This module configure the JournalNode following the 
[HDFS High Availability Using the Quorum Journal Manager][qjm] official 
recommandations.

In order for the Standby node to keep its state synchronized with the Active 
node, both nodes communicate with a group of separate daemons called 
"JournalNodes" (JNs). When any namespace modification is performed by the Active 
node, it durably logs a record of the modification to a majority of these JNs. 
The Standby node is capable of reading the edits from the JNs, and is constantly 
watching them for changes to the edit log.

    module.exports = []

## Configuration

The JournalNode uses properties define inside the "ryba/hadoop/hdfs" module. It
also declare a new property "dfs.journalnode.edits.dir".

*   `hdp.hdfs_site['dfs.journalnode.edits.dir']` (string)   
    The directory where the JournalNode will write transaction logs, default
    to "/var/run/hadoop-hdfs/journalnode\_edit\_dir"

Example:

```json
{
  "ryba": {
    "hdfs_site": {
      "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      ryba.hdfs_site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
      ryba.hdfs_site['dfs.journalnode.http-address'] ?= '0.0.0.0:8480'
      ryba.hdfs_site['dfs.journalnode.https-address'] ?= '0.0.0.0:8481'
      # Kerberos
      ryba.hdfs_site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/#{ryba.static_host}@#{ryba.realm}"
      ryba.hdfs_site['dfs.journalnode.kerberos.principal'] = "HTTP/#{ryba.static_host}@#{ryba.realm}"
      ryba.hdfs_site['dfs.journalnode.keytab.file'] = '/etc/security/keytabs/spnego.service.keytab'
      ryba.hdfs_site['dfs.journalnode.edits.dir'] ?= ['/var/hdfs/edits']
      ryba.hdfs_site['dfs.journalnode.edits.dir'] = ryba.hdfs_site['dfs.journalnode.edits.dir'].join ',' if Array.isArray ryba.hdfs_site['dfs.journalnode.edits.dir']

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/hdfs_jn_backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_jn_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/hdfs_jn_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_jn_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_jn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_jn_stop'


[qjm]: http://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html#Architecture



