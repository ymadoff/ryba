
# HDFS DataNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs').configure

    module.exports.push name: 'Hadoop HDFS DN # Wait', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      contexts = ctx.contexts 'ryba/hadoop/hdfs_dn', require('./hdfs_dn').configure
      servers = for context in contexts
        [_, port] = context.config.ryba.hdfs_site['dfs.datanode.address'].split ':'
        host: context.config.host, port: port
      ctx.waitIsOpen servers, next

## Wait Safemode

Wait for HDFS safemode to exit. It isn't enough to start the NameNodes but the
majority of DataNodes also need to be running.

    module.exports.push name: 'Hadoop HDFS DN # Wait Safemode', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err

## Module Dependencies

    mkcmd = require '../lib/mkcmd'