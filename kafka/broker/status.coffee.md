
# Kafka Broker Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'Kafka Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service kafka-broker status'
        code_skipped: 3
