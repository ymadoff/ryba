---
title: HDFS JournalNode Check
module: ryba/hadoop/hdfs_jn_check
layout: module
---

# HDFS JournalNode Check

Check if the JournalNode is running as expected.

    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push (ctx) ->
      require('./core_ssl').configure ctx
      require('./hdfs_jn').configure ctx

    module.exports.push name: 'HDP HDFS JN Check # SPNEGO', callback: (ctx, next) ->
      {hdfs_site} = ctx.config.hdp
      protocol = if hdfs_site['dfs.http.policy'] is 'HTTPS_ONLY' then 'https' else 'http'
      port = hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{ctx.config.host}:#{port}/"
      , (err, executed, stdout) ->
        return next err if err
        return next Error 'Invalid Response' if stdout.indexOf('<title>JournalNode Information</title>') is -1
        return next err, ctx.PASS


