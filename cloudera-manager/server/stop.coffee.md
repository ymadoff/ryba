# Cloudera Manager Server stop

    module.exports = []

## stop

    module.exports.push name: 'Cloudera Manager Server # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'cloudera-scm-server'
