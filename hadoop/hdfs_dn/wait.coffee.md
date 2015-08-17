
# Hadoop HDFS DataNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('../hdfs').configure

    module.exports.push name: 'HDFS DN # Wait IPC', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      contexts = ctx.contexts 'ryba/hadoop/hdfs_dn', require('./index').configure
      servers = for context in contexts
        [_, port] = context.config.ryba.hdfs.site['dfs.datanode.address'].split ':'
        host: context.config.host, port: port
      ctx.waitIsOpen servers, next

    module.exports.push name: 'HDFS DN # Wait HTTP', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      dn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_dn', require('./index').configure
      servers = for dn_ctx in dn_ctxs
        protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        [_, port] = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split ':'
        host: dn_ctx.config.host, port: port
      ctx.waitIsOpen servers, next

