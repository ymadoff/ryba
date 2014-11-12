---
title: 
layout: module
---

# HDFS SecondaryNameNode Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_snn').configure

    module.exports.push name: 'Hadoop HDFS SNN # Stop', callback: (ctx, next) ->
      lifecycle.snn_stop ctx, next
