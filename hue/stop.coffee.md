
# Hue Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hue # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.hue_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'Hue # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {hue, clean_logs} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: "rm #{hue.log_dir}/*"
        code_skipped: 1
      .then next

## Dependencies

    lifecycle = require '../lib/lifecycle'
