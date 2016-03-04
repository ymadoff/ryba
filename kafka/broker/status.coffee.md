
# Kafka Broker Status

    module.exports = header: 'Kafka Broker Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'kafka-broker'
