---
title: 
layout: module
---

# HBase Start

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Start HBase Master

Execute these commands on the HBase Master host machine.

    module.exports.push name: 'HBase Master # Start', callback: (ctx, next) ->
      lifecycle.hbase_master_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
