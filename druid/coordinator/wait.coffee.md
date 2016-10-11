
# Druid Coordinator Wait

    module.exports = header: 'Druid Coordinator # Wait', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      coordinators = @contexts 'ryba/druid/coordinator', require('./configure').handler
      @connection.wait
        servers: for coordinator in coordinators
          host: coordinator.config.host
          port: coordinator.config.ryba.druid.coordinator.runtime['druid.port']

## Dependencies

    url = require 'url'
