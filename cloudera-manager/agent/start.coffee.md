# Cloudera Manager Agent Start

Cloudera Manager Agent is started with the service's syntax command.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/cloudera-manager/server/wait'


## Start

    module.exports.push header: 'Cloudera Manager Agent # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'cloudera-scm-agent'
