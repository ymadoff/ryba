
# Shinken Poller Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Poller service.

    module.exports.push name: 'Shinken Poller # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-poller'
        action: 'start'
      .then next
