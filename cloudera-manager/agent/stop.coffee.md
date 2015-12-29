# Cloudera Manager Agent stop

    module.exports = []

## stop

    module.exports.push name: 'Cloudera Manager Agent # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'cloudera-scm-agent'
