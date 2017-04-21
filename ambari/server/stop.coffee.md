
# Ambari Server Stop

    module.exports = header: 'Ambari Server Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'ambari-server'
