---
title: 
layout: module
---

# YARN ResourceManager Status

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP ResourceManager # Status', callback: (ctx, next) ->
      lifecycle.rm_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

