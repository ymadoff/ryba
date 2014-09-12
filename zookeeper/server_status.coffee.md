---
title: 
layout: module
---

# Zookeeper Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Status', callback: (ctx, next) ->
      ctx.execute
        cmd: "service zookeeper-server status"
        code_skipped: [1, 3]
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPED'

