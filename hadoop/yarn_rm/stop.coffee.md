
# Hadoop YARN ResourceManager Stop

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Yarn RM # Stop Server', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.rm_stop ctx, next

    module.exports.push name: 'Yarn RM # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {clean_logs, yarn} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn.log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
      .then next
