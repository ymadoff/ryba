
# Shinken Receiver Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'Shinken Receiver # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/receiver'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.receiver.config.port

