
# Shinken Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'
    module.exports.push 'ryba/shinken/reactionner/wait'
    module.exports.push 'ryba/mongodb/start'

## Start

Start the Shinken Broker service.

    module.exports.push name: 'Shinken Broker # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-broker'
        action: 'start'
      .then next
