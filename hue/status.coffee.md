---
title: 
layout: module
---

# Hue Status

    lifecycle = require '../hadoop/lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./install').configure ctx

    module.exports.push name: 'HDP Hue # Status', callback: (ctx, next) ->
      lifecycle.hue_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

