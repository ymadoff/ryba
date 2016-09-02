
# Druid Coordinator Start

    module.exports = header: 'Druid Coordinator # Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'druid-coordinator'
