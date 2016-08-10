
# Druid Coordinator Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'Druid Coordinator # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'druid-coordinator'
