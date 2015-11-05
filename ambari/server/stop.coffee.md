
# Ambari Server stop
 
    module.exports = []

## stop

    module.exports.push header: 'Ambari Server # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'ambari-server'
