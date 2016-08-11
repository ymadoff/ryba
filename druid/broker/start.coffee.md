
# Druid Broker Start

    module.exports = header: 'Druid Broker # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'druid-broker'
