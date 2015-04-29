
# Hadoop HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('../hdfs').configure

    module.exports.push name: 'HDFS NN # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn', require('./index').configure
      servers = for nn_ctx in nn_ctxs
        {nameservice, shortname} = nn_ctx.config.ryba
        protocol = if nn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
        shortname = if nn_ctxs.length > 1 then ".#{shortname}" else ''
        port = nn_ctx.config.ryba.hdfs.site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"].split(':')[1]
        host: nn_ctx.config.host, port: port
      ctx.waitIsOpen servers, next
