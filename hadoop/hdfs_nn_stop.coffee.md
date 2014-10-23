---
title: 
layout: module
---

# HDFS NameNode Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      require('./yarn').configure ctx
      require('./mapred').configure ctx
      throw Error "Not a NameNode" unless ctx.has_module 'ryba/hadoop/hdfs_nn'

    module.exports.push name: 'Hadoop HDFS NN # Stop ZKFC', callback: (ctx, next) ->
      lifecycle.zkfc_stop ctx, next

    module.exports.push name: 'Hadoop HDFS NN # Stop NameNode', callback: (ctx, next) ->
      lifecycle.nn_stop ctx, next

    module.exports.push name: 'Hadoop HDFS NN # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hadoop-hdfs/*/hadoop-hdfs-namenode-*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hadoop-hdfs/*/hadoop-hdfs-zkfc-*'
        code_skipped: 1
      ], next
