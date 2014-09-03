---
title: HDFS DataNode Status
module: ryba/hadoop/hdfs_dn_status
layout: module
---

# HDFS DataNode Status

Display the status of the NameNode as "STARTED" or "STOPPED".

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP HDFS DN # Status', callback: (ctx, next) ->
      lifecycle.dn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
