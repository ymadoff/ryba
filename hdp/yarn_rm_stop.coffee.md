---
title: 
layout: module
---

# YARN ResourceManager Stop

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP ResourceManager # Stop', callback: (ctx, next) ->
      lifecycle.rm_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
