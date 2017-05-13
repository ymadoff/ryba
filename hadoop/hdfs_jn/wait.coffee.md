
# Hadoop HDFS JournalNode Wait

Exemple:

```
nikita.hadoop.hdfs_jn.wait({
    rpc: [
      { "host": "master1.ryba", "port": "8485" },
      { "host": "master2.ryba", "port": "8485" },
      { "host": "master3.ryba", "port": "8485" },
    ]
})
```

    module.exports = header: 'HDFS JN Wait', label_true: 'READY', handler: ->
      options = {}
      options.rpc = for jn_ctx in @contexts 'ryba/hadoop/hdfs_jn'
        [_, port] = jn_ctx.config.ryba.hdfs.site['dfs.journalnode.rpc-address'].split ':'
        host: jn_ctx.config.host, port: port
      
      @connection.wait
        servers: options.rpc
