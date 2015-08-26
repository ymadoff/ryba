
# Hadoop HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('../hdfs').configure

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

## Wait Safemode

Wait for HDFS safemode to exit. It is not enough to start the NameNodes but the
majority of DataNodes also need to be running.

    module.exports.push name: 'HDFS NN # Wait Safemode', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      # TODO: there are much better solutions, for exemple
      # if 'ryba/hadoop/hdfs_client', then `hdfs dfsadmin`
      # else use curl
      return next Error 'HDFS Client Not Installed' unless ctx.has_any_modules 'ryba/hadoop/hdfs_client/install', 'ryba/hadoop/hdfs_nn/install', 'ryba/hadoop/hdfs_snn/install', 'ryba/hadoop/hdfs_dn/install'
      ctx.call (_, callback) ->
        ctx.waitForExecution
          cmd: mkcmd.hdfs ctx, """
            hdfs dfsadmin -safemode get | grep OFF
            """
          interval: 3000
        , callback
      .then (err) -> next err, true

## Dependencies

    mkcmd = require '../../lib/mkcmd'
