---
title: 
layout: module
---

# MapRed JobHistoryServer Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./mapred').configure ctx

    module.exports.push name: 'HDP MapRed JHS # Start', callback: (ctx, next) ->
      lifecycle.jhs_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
