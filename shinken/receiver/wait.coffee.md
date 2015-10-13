
# Shinken Receiver Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'Shinken Receiver # Wait', label_true: 'READY', handler: ->
      @wait_connect @contexts('ryba/shinken/receiver').map((ctx) -> 
        host: ctx.config.host
        port: ctx.config.ryba.shinken.reactionner.config.port
      )
