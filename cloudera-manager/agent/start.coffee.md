# Cloudera Manager Agent Start

Cloudera Manager Agent is started with the service's syntax command.

    module.exports = header: 'Cloudera Manager Agent Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'cloudera-scm-agent'
