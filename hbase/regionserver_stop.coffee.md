---
title: 
layout: module
---

# HBase RegionServer Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Stop Server

Execute these commands on all RegionServers.

    module.exports.push name: 'HBase RegionServer # Stop Server', label_true: 'STOPED', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'HBase RegionServer # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hbase/*-regionserver-*'
        code_skipped: 1
      , next
