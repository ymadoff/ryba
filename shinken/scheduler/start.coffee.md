
# Shinken Scheduler Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Stop the Shinken Scheduler service.

    module.exports.push name: 'Shinken Scheduler # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-scheduler'
        action: 'start'
      .then next
