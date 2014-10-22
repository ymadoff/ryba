---
title: 
layout: module
---

# YARN ResourceManager Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP ResourceManager # Stop Server', callback: (ctx, next) ->
      lifecycle.rm_stop ctx, next

    module.exports.push name: 'HDP ResourceManager # Stop Clean Logs', callback: (ctx, next) ->
      {clean_logs, yarn_log_dir} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn_log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
      , next
