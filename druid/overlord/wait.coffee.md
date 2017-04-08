
# Druid Overlord Wait

    module.exports = header: 'Druid Overlord Wait', label_true: 'STOPPED', handler: ->
      overlords = @contexts 'ryba/druid/overlord'
      @connection.wait
        servers: for overlord in overlords
          host: overlord.config.host
          port: overlord.config.ryba.druid.overlord.runtime['druid.port']

## Dependencies

    url = require 'url'
