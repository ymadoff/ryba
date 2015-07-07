
# Shinken Arbiter Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'
    module.exports.push 'ryba/shinken/reactionner/wait'
    module.exports.push 'ryba/shinken/broker/wait'

## Start

    module.exports.push name: 'Shinken Arbiter # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-arbiter'
        action: 'start'
      .then next
