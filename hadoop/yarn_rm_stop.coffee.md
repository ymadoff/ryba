---
title: 
layout: module
---

# YARN ResourceManager Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./yarn_rm').configure

    module.exports.push name: 'Hadoop ResourceManager # Stop Server', label_true: 'STOPED', callback: (ctx, next) ->
      lifecycle.rm_stop ctx, next

    module.exports.push name: 'Hadoop ResourceManager # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      {clean_logs, yarn_log_dir} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn_log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
      , next
