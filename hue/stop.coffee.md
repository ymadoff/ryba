---
title: 
layout: module
---

# Hue Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hue # Stop', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.hue_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'Hue # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hue/*'
        code_skipped: 1
      , next


