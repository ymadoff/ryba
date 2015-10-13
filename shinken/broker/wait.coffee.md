
# Shinken Broker Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Shinken Broker # Wait', label_true: 'READY', handler: ->
      @wait_connect @contexts('ryba/shinken/broker').map((ctx) -> 
        host: ctx.config.host
        port: ctx.config.ryba.shinken.broker.config.port
      )
