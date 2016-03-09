
# Shinken Reactionner Wait

    module.exports = header: 'Shinken Reactionner Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/reactionner'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.reactionner.config.port
