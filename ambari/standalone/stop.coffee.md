
# Ambari Server Stop

    module.exports = header: 'Ambari Standalone Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'ambari-server'
