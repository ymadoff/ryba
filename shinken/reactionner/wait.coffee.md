
# Shinken Reactionner Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'

## Wait

    module.exports.push header: 'Shinken Reactionner # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/reactionner'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.reactionner.config.port
