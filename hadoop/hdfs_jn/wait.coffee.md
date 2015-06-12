
# Hadoop HDFS JournalNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'HDFS JN # Wait', label_true: 'READY', handler: (ctx, next) ->
      jn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_jn', require('./index').configure
      servers = for jn_ctx in jn_ctxs
        [_, port] = jn_ctx.config.ryba.hdfs.site['dfs.journalnode.rpc-address'].split ':'
        host: jn_ctx.config.host, port: port
      ctx.waitIsOpen servers, next
