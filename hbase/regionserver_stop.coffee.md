---
title: 
layout: module
---

# HBase Stop

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Stop HBase Region Server

Execute these commands on all RegionServers.

    module.exports.push name: 'HBase RegionServer # Stop', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_stop ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
