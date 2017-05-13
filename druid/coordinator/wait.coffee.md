
# Druid Coordinator Wait

    module.exports = header: 'Druid Coordinator Wait', label_true: 'STOPPED', handler: ->
      options = {}
      options.wait_tcp = for coordinator in @contexts 'ryba/druid/coordinator'
        host: coordinator.config.host
        port: coordinator.config.ryba.druid.coordinator.runtime['druid.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
