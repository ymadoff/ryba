
# Druid Broker Wait

    module.exports = header: 'Druid Broker # Wait', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      brokers = @contexts 'ryba/druid/broker', require('./configure').handler
      @connection.wait
        servers: for broker in brokers
          host: broker.config.host
          port: broker.config.ryba.druid.broker.runtime['druid.port']

## Dependencies

    url = require 'url'
