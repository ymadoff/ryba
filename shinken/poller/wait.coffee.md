
# Shinken Poller Wait

    module.exports = header: 'Shinken Poller Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/poller'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.poller.config.port
