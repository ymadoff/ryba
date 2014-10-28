---
title: 
layout: module
---

# Hue Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hue # Stop', callback: (ctx, next) ->
      lifecycle.hue_stop ctx, next


