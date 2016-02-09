# Cloudera Manager Agent stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## stop

    module.exports.push header: 'Cloudera Manager Agent # Stop', label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'cloudera-scm-agent'
