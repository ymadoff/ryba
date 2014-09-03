---
title: 
layout: module
---

# Hue Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./install').configure ctx

    module.exports.push name: 'HDP Hue # Stop', callback: (ctx, next) ->
      lifecycle.hue_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS


