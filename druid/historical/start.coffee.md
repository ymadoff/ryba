
# Druid Historical Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'Druid Historical # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'druid-historical'
