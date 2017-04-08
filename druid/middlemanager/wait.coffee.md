
# Druid MiddleManager Wait

    module.exports = header: 'Druid MiddleManager Wait', label_true: 'STOPPED', handler: ->
      middlemanagers = @contexts 'ryba/druid/middlemanager'
      @connection.wait
        servers: for middlemanager in middlemanagers
          host: middlemanager.config.host
          port: middlemanager.config.ryba.druid.middlemanager.runtime['druid.port']

## Dependencies

    url = require 'url'
