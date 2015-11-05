
# Shinken Scheduler Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push header: 'Shinken Scheduler # Wait', label_true: 'READY', handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/shinken/scheduler'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.scheduler.config.port
