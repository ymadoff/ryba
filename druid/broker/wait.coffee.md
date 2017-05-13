
# Druid Broker Wait

    module.exports = header: 'Druid Broker Wait', label_true: 'STOPPED', handler: ->
      options = {}
      options.wait_tcp = for broker in @contexts 'ryba/druid/broker'
        host: broker.config.host
        port: broker.config.ryba.druid.broker.runtime['druid.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
