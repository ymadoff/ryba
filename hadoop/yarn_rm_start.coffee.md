---
title: 
layout: module
---

# YARN ResourceManager Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'Hadoop ResourceManager # Start Server', callback: (ctx, next) ->
      lifecycle.rm_start ctx, next