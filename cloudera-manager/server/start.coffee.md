
# Cloudera Manager Server Start

Cloudera Manager Agent is started with the service's syntax command.

    module.exports = header: 'Cloudera Manager Server Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'cloudera-scm-server'
