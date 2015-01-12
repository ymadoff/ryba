
# YARN NodeManager Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'Hadoop NodeManager # Stop Server', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.nm_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

    module.exports.push name: 'Hadoop NodeManager # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      {clean_logs, yarn} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
        code_skipped: 1
      , next
