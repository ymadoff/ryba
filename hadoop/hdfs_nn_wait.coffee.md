
# HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs').configure

    module.exports.push name: 'Hadoop HDFS NN # Wait', timeout: -1, callback: (ctx, next) ->
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn', require('./hdfs_nn').configure
      servers = for nn_ctx in nn_ctxs
        {nameservice, shortname} = nn_ctx.config.ryba
        protocol = if nn_ctx.config.ryba.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
        shortname = if nn_ctxs.length > 1 then ".#{shortname}" else ''
        port = nn_ctx.config.ryba.hdfs_site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"].split(':')[1]
        host: nn_ctx.config.host, port: port
      ctx.waitIsOpen servers, next

    module.exports.push name: 'Hadoop HDFS NN # Wait Safemode', timeout: -1, callback: (ctx, next) ->
      # Safemode need some database started datanode to exit
      # Because './nn_check' depends on this module, we cant stop now or no
      # datanode may be started
      return next() if ctx.has_module 'ryba/hadoop/hdfs_dn'
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err

## Module Dependencies

    mkcmd = require '../lib/mkcmd'
