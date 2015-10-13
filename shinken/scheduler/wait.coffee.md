
# Shinken Scheduler Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'Shinken Scheduler # Wait', label_true: 'READY', handler: ->
      @wait_connect @contexts('ryba/shinken/scheduler').map((ctx) -> 
        host: ctx.config.host
        port: ctx.config.ryba.shinken.scheduler.config.port
      )
