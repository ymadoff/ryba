
# Druid Overlord Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'Druid Overlord # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'druid-overlord'
