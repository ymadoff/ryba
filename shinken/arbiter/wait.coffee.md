
# Shinken Arbiter Wait

    module.exports = header: 'Shinken Arbiter Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/arbiter'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.arbiter.config.port
