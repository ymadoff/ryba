---
title: 
layout: module
---

# HBase Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Stop HBase Master

Execute these commands on the HBase Master host machine.

    module.exports.push name: 'HBase Master # Stop', callback: (ctx, next) ->
      lifecycle.hbase_master_stop ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
