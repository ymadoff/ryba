
# Cloudera Manager Server stop

    module.exports = header: 'Cloudera Manager Server Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'cloudera-scm-server'
