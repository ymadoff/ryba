
# Cloudera Manager Server stop

    module.exports = header: 'Cloudera Manager Server Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'cloudera-scm-server'
