
# Shinken Reactionner Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'

## Wait

    module.exports.push name: 'Shinken Poller # Wait', label_true: 'READY', handler: ->
      @wait_connect @contexts('ryba/shinken/reactionner').map((ctx) -> 
        host: ctx.config.host
        port: ctx.config.ryba.shinken.reactionner.config.port
      )
