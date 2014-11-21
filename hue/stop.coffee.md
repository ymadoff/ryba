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

## Stop Clean Logs

    module.exports.push name: 'Hue # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hue/*'
        code_skipped: 1
      , next


