---
title: 
layout: module
---

# HDFS NameNode Status

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP HDFS NN # Status NameNode', callback: (ctx, next) ->
      lifecycle.nn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

    module.exports.push name: 'HDP HDFS NN # Status ZKFC', callback: (ctx, next) ->
      lifecycle.zkfc_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
