---
title: HDFS JournalNode Status
module: ryba/hadoop/hdfs_jn_status
layout: module
---

# HDFS JournalNode Status

Display the status of the JournalNode as "STARTED" or "STOPPED".

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_jn').configure

    module.exports.push name: 'Hadoop HDFS JN # Status', callback: (ctx, next) ->
      lifecycle.jn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
