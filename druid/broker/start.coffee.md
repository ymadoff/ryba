
# Druid Broker Start

    module.exports = header: 'Druid Broker # Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'druid-broker'
