---
title: 
layout: module
---

# Zookeeper Start

    lifecycle = require './lib/lifecycle'
    hdp_zookeeper = require './zookeeper'
    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push (ctx) ->
      require('./zookeeper').configure ctx

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'HDP ZooKeeper # Start', callback: (ctx, next) ->
      {zookeeper_user} = ctx.config.hdp
      lifecycle.zookeeper_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

