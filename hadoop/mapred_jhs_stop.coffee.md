---
title: 
layout: module
---

# MapRed JobHistoryServer Stop

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./mapred').configure ctx

    module.exports.push name: 'HDP JobHistoryServer # Stop', callback: (ctx, next) ->
      lifecycle.jhs_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
