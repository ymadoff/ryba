
# Shinken Poller Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'Shinken Poller # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/poller'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.poller.config.port

