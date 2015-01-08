
# Hadoop HDFS JournalNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop MapRed JHS # Wait', label_true: 'READY', callback: (ctx, next) ->
      jn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_jn', require('./hdfs_jn').configure
      servers = for jn_ctx in jn_ctxs
        [_, port] = jn_ctx.config.ryba.hdfs_site['dfs.journalnode.rpc-address'].split ':'
        host: jn_ctx.config.host, port: port
      ctx.waitIsOpen servers, next
