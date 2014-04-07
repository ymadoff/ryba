---
title: 
layout: module
---

# Hue Status

    lifecycle = require './lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hue').configure ctx

    module.exports.push name: 'HDP Hue # Status', callback: (ctx, next) ->
      lifecycle.hue_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

