
# Druid Historical Wait

    module.exports = header: 'Druid Historical Wait', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      historicals = @contexts 'ryba/druid/historical', require('./configure').handler
      @connection.wait
        servers: for historical in historicals
          host: historical.config.host
          port: historical.config.ryba.druid.historical.runtime['druid.port']

## Dependencies

    url = require 'url'
