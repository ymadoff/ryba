---
title: 
layout: module
---

# Oozie Server Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

## Stop

Stop the Oozie service. Execute these commands on the Oozie server host machine.

    module.exports.push name: 'Oozie Server # Stop', label_true: 'STOPED', timeout: -1, callback: (ctx, next) ->
      lifecycle.oozie_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'Oozie Server # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/oozie/*'
        code_skipped: 1
      , next
