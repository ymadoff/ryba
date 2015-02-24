
# Hadoop HDFS DataNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs').configure

    module.exports.push name: 'HDFS DN # Wait', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      contexts = ctx.contexts 'ryba/hadoop/hdfs_dn', require('./hdfs_dn').configure
      servers = for context in contexts
        [_, port] = context.config.ryba.hdfs.site['dfs.datanode.address'].split ':'
        host: context.config.host, port: port
      ctx.waitIsOpen servers, next

## Wait Safemode

Wait for HDFS safemode to exit. It isn't enough to start the NameNodes but the
majority of DataNodes also need to be running.

# This middleware duplicates the one present in 'masson/hadoop/hdfs_nn_start' and
# is only called if a NameNode is installed on this server because a NameNode need
# a mojority of DataNodes to be started in order to exit safe mode.

    module.exports.push name: 'HDFS DN # Wait Safemode', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      # return next() unless ctx.has_module 'ryba/hadoop/hdfs_nn'
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err, true

## Wait Failover

Ensure a given NameNode is always active and force the failover otherwise.

In order to work properly, the ZKFC daemon must be running and the command must
be executed on the same server as ZKFC.

This middleware duplicates the one present in 'masson/hadoop/hdfs_nn_wait' and
is only called if a NameNode is installed on this server because this command
only run on a NameNode with fencing installed and in normal mode.

    module.exports.push name: 'HDFS DN Start # Wait Failover', handler: (ctx, next) ->
      return next() unless ctx.has_module 'ryba/hadoop/hdfs_nn'
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      {active_nn_host, standby_nn_host} = ctx.config.ryba
      active_nn_host = active_nn_host.split('.')[0]
      standby_nn_host = standby_nn_host.split('.')[0]
      # This command seems to crash the standby namenode when it is made active and
      # when the active_nn is restarting and still in safemode
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs haadmin -getServiceState #{active_nn_host} | grep standby;
        then hdfs haadmin -failover #{standby_nn_host} #{active_nn_host};
        else exit 2; fi
        """
        code_skipped: 2
      , next

## Module Dependencies

    mkcmd = require '../lib/mkcmd'