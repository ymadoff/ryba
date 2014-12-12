---
title: 
layout: module
---

# Hue Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hue # Start', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hue_start ctx, next


