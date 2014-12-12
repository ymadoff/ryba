---
title: 
layout: module
---

# HDFS SecondaryNameNode Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_snn').configure

    module.exports.push name: 'Hadoop HDFS SNN # Start', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.snn_start ctx, next

    # module.exports.push name: 'Hadoop HDFS SNN # Wait', callback: (ctx, next) ->
    #   [host, port] = hdfs_site['dfs.namenode.secondary.http-address'].split ':'
    #   ctx.waitIsOpen host, port, next
