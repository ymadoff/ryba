
# Hadoop HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('../hdfs').configure

    module.exports.push header: 'HDFS NN # Wait', timeout: -1, label_true: 'READY', handler:  ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'#, require('./index').configure
      @wait_connect
        servers: for nn_ctx in nn_ctxs
          {nameservice} = nn_ctx.config.ryba
          protocol = if nn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
          shortname = if nn_ctxs.length > 1 then ".#{nn_ctx.config.shortname}" else ''
          port = nn_ctx.config.ryba.hdfs.site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"].split(':')[1]
          host: nn_ctx.config.host, port: port

## Wait Safemode

Wait for HDFS safemode to exit. It is not enough to start the NameNodes but the
majority of DataNodes also need to be running.

    module.exports.push header: 'HDFS NN # Wait Safemode', timeout: -1, label_true: 'READY', handler:  ->
      # TODO: there are much better solutions, for exemple
      # if 'ryba/hadoop/hdfs_client', then `hdfs dfsadmin`
      # else use curl
      throw Error 'HDFS Client Not Installed' unless @has_any_modules 'ryba/hadoop/hdfs_client/install', 'ryba/hadoop/hdfs_nn/install', 'ryba/hadoop/hdfs_snn/install', 'ryba/hadoop/hdfs_dn/install'
      @wait_execute
        cmd: mkcmd.hdfs @, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000

## Dependencies

    mkcmd = require '../../lib/mkcmd'
