---
title: 
layout: module
---

# HBase Start

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Start HBase Region Server

Execute these commands on all RegionServers.

    module.exports.push name: 'HBase RegionServer # Start', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
