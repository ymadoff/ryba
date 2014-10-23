---
title: 
layout: module
---

# HDFS SecondaryNameNode Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      return next new Error "Not an Secondary NameNode" unless ctx.has_module 'ryba/hadoop/hdfs_snn'

    module.exports.push name: 'Hadoop HDFS SNN # Start', callback: (ctx, next) ->
      lifecycle.snn_start ctx, next

    # module.exports.push name: 'Hadoop HDFS SNN # Wait', callback: (ctx, next) ->
    #   [host, port] = hdfs_site['dfs.namenode.secondary.http-address'].split ':'
    #   ctx.waitIsOpen host, port, next
