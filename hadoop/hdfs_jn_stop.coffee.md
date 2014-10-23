---
title: HDFS JournalNode Stop
module: ryba/hadoop/hdfs_jn_stop
layout: module
---

# HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its 
associated NameNodes.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'Hadoop HDFS JN # Stop', callback: (ctx, next) ->
      lifecycle.jn_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

    module.exports.push name: 'Hadoop HDFS JN # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/hadoop-hdfs-journalnode-*'
        code_skipped: 1
      , next
