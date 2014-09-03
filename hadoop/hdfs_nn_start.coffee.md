---
title: HDP NameNode Start
module: ryba/hadoop/hdfs_nn_start
layout: module
---

# HDFS NameNode Start

Start the NameNode service as well as its ZKFC daemon. To ensure that the 
leadership is assigned to the desired active NameNode, the ZKFC daemons on
the standy NameNodes wait for the one on the active NameNode to start first.

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push require('./hdfs').configure

## Start

# Wait for all JournalNodes to be started before starting this NameNode if it wasn't yet started
# during the HDFS format phase.

    module.exports.push name: 'HDP HDFS NN # Start NameNode', callback: (ctx, next) ->
      lifecycle.nn_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS NN # Start ZKFC', callback: (ctx, next) ->
      # ZKFC should start first on active NameNode
      {active_nn, active_nn_host} = ctx.config.hdp
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
          next err, if started then ctx.OK else ctx.PASS
      if active_nn then do_start() else do_wait()

    module.exports.push name: 'HDFS HDFS NN Start # Activate', callback: (ctx, next) ->
      {active_nn, active_nn_host, standby_nn_host} = ctx.config.hdp
      return next() unless active_nn
      active_nn_host = active_nn_host.split('.')[0]
      standby_nn_host = standby_nn_host.split('.')[0]
      # This command seems to crash the standby namenode when it is made active and
      # when the active_nn is restarting and still in safemode
      ctx.execute
        cmd: mkcmd.hdfs ctx, "if hdfs haadmin -getServiceState #{active_nn_host} | grep standby; then hdfs haadmin -failover #{standby_nn_host} #{active_nn_host}; else exit 2; fi"
        code_skipped: 2
      , (err, activated) ->
        next err, if activated then ctx.OK else ctx.PASS

## Module Dependencies

    url = require 'url'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'

