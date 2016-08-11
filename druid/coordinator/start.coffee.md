
# Druid Coordinator Start

    module.exports = header: 'Druid Coordinator # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'druid-coordinator'
