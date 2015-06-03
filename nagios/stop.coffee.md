
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the nagios service.

    module.exports.push name: 'Nagios # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'nagios'
        action: 'stop'
      .then next

## Stop Clean Logs

    module.exports.push name: 'Nagios # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/nagios/*'
        code_skipped: 1
      .then next
