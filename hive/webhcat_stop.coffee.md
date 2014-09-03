---
title: 
layout: module
---

# WebHCat Stop

    lifecycle = require '../lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./webhcat').configure ctx

    module.exports.push name: 'HDP WebHCat # Stop', callback: (ctx, next) ->
      lifecycle.webhcat_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
