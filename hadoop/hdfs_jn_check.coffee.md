---
title: HDFS JournalNode Check
module: ryba/hadoop/hdfs_jn_check
layout: module
---

# HDFS JournalNode Check

Check if the JournalNode is running as expected.

    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'HDP HDFS JN Check # SPNEGO', callback: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -u : http://#{ctx.config.host}:8480/"
      , (err, executed, stdout) ->
        return next err if err
        return next Error 'Invalid Response' if stdout.indexOf('<title>JournalNode Information</title>') is -1
        return next err, ctx.PASS


