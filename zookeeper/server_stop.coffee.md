---
title: 
layout: module
---

# Zookeeper Stop

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

## Stop

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'HDP ZooKeeper # Stop', callback: (ctx, next) ->
      lifecycle.zookeeper_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

