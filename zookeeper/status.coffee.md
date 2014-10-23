---
title: 
layout: module
---

# Zookeeper Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

    module.exports.push name: 'ZooKeeper # Status', callback: (ctx, next) ->
      lifecycle.zookeeper_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

