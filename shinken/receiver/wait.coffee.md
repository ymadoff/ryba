
# Shinken Receiver Wait

    module.exports = header: 'Shinken Receiver Wait', label_true: 'READY', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/shinken/receiver'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.receiver.config.port
