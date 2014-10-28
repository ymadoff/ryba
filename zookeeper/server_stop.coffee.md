---
title: 
layout: module
---

# Zookeeper Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Stop

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Stop', callback: (ctx, next) ->
      lifecycle.zookeeper_stop ctx, next

