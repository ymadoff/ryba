# Cloudera Manager Server stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## stop

    module.exports.push header: 'Cloudera Manager Server # Stop', label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'cloudera-scm-server'
