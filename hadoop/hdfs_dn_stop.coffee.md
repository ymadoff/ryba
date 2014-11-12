---
title: HDFS DataNode Stop
module: ryba/hadoop/hdfs_dn_stop
layout: module
---

# HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its 
associated the NameNodes.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_dn').configure

    module.exports.push name: 'Hadoop HDFS DN # Stop', callback: (ctx, next) ->
      ctx.execute
        cmd: "service hadoop-hdfs-datanode stop"
        code_skipped: 3
      , next

    module.exports.push name: 'Hadoop HDFS DN # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/hadoop-hdfs-datanode-*'
        code_skipped: 1
      , next