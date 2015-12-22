
# Kafka Broker Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push header: 'Kafka Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'kafka-broker'
