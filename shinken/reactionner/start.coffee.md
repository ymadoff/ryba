
# Shinken Reactionner Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'

## Start

Start the Shinken Reactionner service.

    module.exports.push name: 'Shinken Reactionner # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-reactionner'
        action: 'start'
      .then next
