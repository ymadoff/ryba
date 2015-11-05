
# Shinken Broker Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push header: 'Shinken Broker # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/broker'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.broker.config.port
