
# Shinken Receiver Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Receiver service.

    module.exports.push name: 'Shinken Receiver # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-receiver'
        action: 'stop'
      .then next

## Clean Logs

    module.exports.push name: 'Shinken Receiver # Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
      .then next
