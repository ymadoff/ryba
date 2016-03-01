
# Hadoop HDFS JournalNode Wait

    module.exports = header: 'HDFS JN # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for jn_ctx in @contexts 'ryba/hadoop/hdfs_jn'
          [_, port] = jn_ctx.config.ryba.hdfs.site['dfs.journalnode.rpc-address'].split ':'
          host: jn_ctx.config.host, port: port
