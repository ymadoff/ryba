
# Hadoop HDFS NameNode Start

Start the NameNode service as well as its ZKFC daemon. To ensure that the 
leadership is assigned to the desired active NameNode, the ZKFC daemons on
the standy NameNodes wait for the one on the active NameNode to start first.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/xasecure/policymgr_wait'
    module.exports.push 'ryba/hadoop/hdfs_jn_wait'
    module.exports.push require('./hdfs_nn').configure

## Start

Wait for all JournalNodes to be started before starting this NameNode if it wasn't yet started
during the HDFS format phase.

    module.exports.push name: 'HDFS NN # Start NameNode', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.nn_start ctx, next

## Wait Safemode

Wait for HDFS safemode to exit. It isn't enough to start the NameNodes but the
majority of DataNodes also need to be running.

This middleware duplicates the one present in 'masson/hadoop/hdfs_dn_wait' and
is only called if a DataNode isn't installed on this server because a NameNode
need a mojority of DataNodes to be started in order to exit safe mode.

    module.exports.push name: 'HDFS DN # Wait Safemode', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      return next() if ctx.has_module 'ryba/hadoop/hdfs_dn'
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err

    module.exports.push name: 'HDFS NN # Start ZKFC', label_true: 'STARTED', handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      # ZKFC should start first on active NameNode
      {active_nn, active_nn_host} = ctx.config.ryba
      do_wait = ->
        ctx.waitForExecution
          # hdfs haadmin -getServiceState hadoop1
          cmd: mkcmd.hdfs ctx, "hdfs haadmin -getServiceState #{active_nn_host.split('.')[0]}"
          code_skipped: 255
        , (err, stdout) ->
          return next err if err
          do_start()
      do_start = ->
        lifecycle.zkfc_start ctx, (err, started) ->
          next err, started
      if active_nn then do_start() else do_wait()

## Wait Failover

Ensure a given NameNode is always active and force the failover otherwise.

In order to work properly, the ZKFC daemon must be running and the command must
be executed on the same server as ZKFC.

This middleware duplicates the one present in 'masson/hadoop/hdfs_dn_wait' and
is only called if a DataNode isn't installed on this server because this command
only run on a NameNode with fencing installed and in normal mode.

    module.exports.push name: 'HDFS DN Start # Wait Failover', label_true: 'READY', handler: (ctx, next) ->
      return next() if ctx.has_module 'ryba/hadoop/hdfs_dn'
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

    url = require 'url'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'

