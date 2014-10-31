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
    module.exports.push require('./hdfs_nn').configure
    module.exports.push 'ryba/xasecure/policymgr_wait'

## Start

# Wait for all JournalNodes to be started before starting this NameNode if it wasn't yet started
# during the HDFS format phase.

    module.exports.push name: 'Hadoop HDFS NN # Start NameNode', callback: (ctx, next) ->
      lifecycle.nn_start ctx, next

    module.exports.push name: 'Hadoop HDFS NN # Wait NameNode', callback: (ctx, next) ->
      if ctx.host_with_module 'ryba/hadoop/hdfs_snn'
        next()
      else
        {hdfs_site, nameservice, ha_client_config, hdfs_namenode_timeout} = ctx.config.ryba
        ipc_port = ha_client_config["dfs.namenode.rpc-address.#{nameservice}.#{ctx.config.shortname}"].split(':')[1] or 8020
        protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        http_port = ha_client_config["dfs.namenode.#{protocol}-address.#{nameservice}.#{ctx.config.shortname}"].split(':')[1]
        ctx.waitIsOpen ctx.config.host, [ipc_port, http_port], timeout: hdfs_namenode_timeout, (err) ->
          next err, false

    module.exports.push name: 'Hadoop HDFS NN # Start ZKFC', callback: (ctx, next) ->
      return next() if ctx.host_with_module 'ryba/hadoop/hdfs_snn'
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

    module.exports.push name: 'HDFS HDFS NN Start # Activate', callback: (ctx, next) ->
      return next() if ctx.host_with_module 'ryba/hadoop/hdfs_snn'
      {active_nn, active_nn_host, standby_nn_host} = ctx.config.ryba
      return next() unless active_nn
      active_nn_host = active_nn_host.split('.')[0]
      standby_nn_host = standby_nn_host.split('.')[0]
      # This command seems to crash the standby namenode when it is made active and
      # when the active_nn is restarting and still in safemode
      ctx.execute
        cmd: mkcmd.hdfs ctx, "if hdfs haadmin -getServiceState #{active_nn_host} | grep standby; then hdfs haadmin -failover #{standby_nn_host} #{active_nn_host}; else exit 2; fi"
        code_skipped: 2
      , next

## Module Dependencies

    url = require 'url'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'

