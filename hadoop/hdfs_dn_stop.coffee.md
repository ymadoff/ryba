---
title: HDFS DataNode Stop
module: phyla/hadoop/hdfs_dn_stop
layout: module
---

# HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its 
associated the NameNodes.

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP HDFS DN # Stop', callback: (ctx, next) ->
      return next new Error "Not an DataNode" unless ctx.has_module 'phyla/hadoop/hdfs_dn'
      lifecycle.dn_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS