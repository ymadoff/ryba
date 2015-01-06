---
title: 
layout: module
---

# Zookeeper Server Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Stop

Stop the Zookeeper service. Execute these commands on all the ZooKeeper host
machines.

    module.exports.push name: 'ZooKeeper Server # Stop', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.zookeeper_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'Oozie Server # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/zookeeper/*'
        code_skipped: 1
      , next

