
# Shinken Scheduler Wait

    module.exports = header: 'Shinken Scheduler Wait', label_true: 'READY', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/shinken/scheduler'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.scheduler.config.port
