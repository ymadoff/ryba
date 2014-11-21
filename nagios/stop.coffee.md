
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the nagios service.

    module.exports.push name: 'Nagios # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'nagios'
        action: 'stop'
      , next

## Stop Clean Logs

    module.exports.push name: 'Nagios # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/nagios/*'
        code_skipped: 1
      , next
