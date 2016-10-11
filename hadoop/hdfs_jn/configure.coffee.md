
# Hadoop HDFS JournalNode Configure

The JournalNode uses properties define inside the "ryba/hadoop/hdfs" module. It
also declare a new property "dfs.journalnode.edits.dir".

*   `hdp.hdfs.site['dfs.journalnode.edits.dir']` (string)   
    The directory where the JournalNode will write transaction logs, default
    to "/var/run/hadoop-hdfs/journalnode\_edit\_dir"

Example:

```json
{
  "ryba": {
    "hdfs.site": {
      "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
    }
  }
}
```

    module.exports = ->
      # nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn', require('../hdfs_nn/configure').handler
      # throw Error "HDFS not configured for HA" unless nn_ctxs.length is 2
      {ryba} = @config
      ryba.hdfs.jn ?= {}
      ryba.hdfs.jn.conf_dir ?= '/etc/hadoop-hdfs-journalnode/conf'
      ryba.hdfs.site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
      ryba.hdfs.site['dfs.journalnode.http-address'] ?= '0.0.0.0:8480'
      ryba.hdfs.site['dfs.journalnode.https-address'] ?= '0.0.0.0:8481'
      ryba.hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      # Kerberos
      # TODO: Principal should be "jn/{host}@{realm}", however, there is
      # no properties to have a separated keytab between jn and spnego principals
      ryba.hdfs.site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.site['dfs.journalnode.kerberos.principal'] = "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.site['dfs.journalnode.keytab.file'] = '/etc/security/keytabs/spnego.service.keytab'
      # ryba.hdfs.site['dfs.journalnode.edits.dir'] ?= ['file:///var/hdfs/edits']
      ryba.hdfs.site['dfs.journalnode.edits.dir'] ?= ['/var/hdfs/edits']
      ryba.hdfs.site['dfs.journalnode.edits.dir'] = ryba.hdfs.site['dfs.journalnode.edits.dir'].join ',' if Array.isArray ryba.hdfs.site['dfs.journalnode.edits.dir']
      # ryba.hdfs.site['dfs.namenode.shared.edits.dir'] ?= nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir']
