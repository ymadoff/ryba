
# Kafka Broker Status

    module.exports = header: 'Kafka Broker Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'kafka-broker'
