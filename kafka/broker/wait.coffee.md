
# HBase Master Wait

    module.exports =  header: 'Kafka Broker Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.brokers = for ks_ctx in @contexts 'ryba/kafka/broker'
        for protocol in ks_ctx.config.ryba.kafka.broker.protocols
          host: ks_ctx.config.host
          port: ks_ctx.config.ryba.kafka.broker.ports[protocol]

## Broker Port

      @connection.wait
        header: 'Broker'
        servers: options.brokers
          
