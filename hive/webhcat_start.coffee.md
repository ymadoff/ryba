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

    module.exports.push name: 'WebHCat # Start', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.webhcat_start ctx, next
