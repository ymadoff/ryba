---
title: 
layout: module
---

# Hue Start

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./install').configure ctx

    module.exports.push name: 'HDP Hue # Start', callback: (ctx, next) ->
      lifecycle.hue_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS


