---
title: 
layout: module
---

# YARN NodeManager Stop

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP NodeManager # Stop', callback: (ctx, next) ->
      lifecycle.nm_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
