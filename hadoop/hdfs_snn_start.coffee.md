---
title: 
layout: module
---

# HDFS SecondaryNameNode Start

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP HDFS SNN # Start', callback: (ctx, next) ->
      return next new Error "Not an Secondary NameNode" unless ctx.has_module 'phyla/hadoop/hdfs_snn'
      lifecycle.snn_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
