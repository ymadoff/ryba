---
title: 
layout: module
---

# WebHCat Stop

    lifecycle = require '../lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./webhcat').configure ctx

    module.exports.push name: 'WebHCat # Stop', callback: (ctx, next) ->
      lifecycle.webhcat_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'WebHCat # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/webhcat/webhcat-console*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/webhcat/webhcat.log*'
        code_skipped: 1
      ], next
