
# Hadoop HDFS JournalNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'HDFS JN # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for jn_ctx in @contexts 'ryba/hadoop/hdfs_jn'#, require('./index').configure
          [_, port] = jn_ctx.config.ryba.hdfs.site['dfs.journalnode.rpc-address'].split ':'
          host: jn_ctx.config.host, port: port
