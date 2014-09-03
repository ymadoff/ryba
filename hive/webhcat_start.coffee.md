---
title: 
layout: module
---

# WebHCat Start

    lifecycle = require '../lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./webhcat').configure ctx

    module.exports.push name: 'WebHCat # Start', callback: (ctx, next) ->
      lifecycle.webhcat_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
