
# Druid Overlord Wait

    module.exports = header: 'Druid Overlord # Wait', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      overlords = @contexts 'ryba/druid/overlord', require('./configure').handler
      @connection.wait
        servers: for overlord in overlords
          host: overlord.config.host
          port: overlord.config.ryba.druid.overlord.runtime['druid.port']

## Dependencies

    url = require 'url'
