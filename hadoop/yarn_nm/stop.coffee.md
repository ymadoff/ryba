
# YARN NodeManager Stop

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hadoop NodeManager # Stop Server', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.nm_stop ctx, (err, stopped) ->
        next err, stopped

    module.exports.push name: 'Hadoop NodeManager # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {clean_logs, yarn} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
        code_skipped: 1
      .then next
