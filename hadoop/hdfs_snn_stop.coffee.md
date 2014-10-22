---
title: 
layout: module
---

# HDFS SecondaryNameNode Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      return next new Error "Not an Secondary NameNode" unless ctx.has_module 'ryba/hadoop/hdfs_snn'

    module.exports.push name: 'HDP HDFS SNN # Stop', callback: (ctx, next) ->
      lifecycle.snn_stop ctx, next
