
# Shinken Receiver Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/shinken/scheduler/wait'

## Start

Start the Shinken Receiver service.

    module.exports.push name: 'Shinken Receiver # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-broker'
        action: 'start'
      .then next
