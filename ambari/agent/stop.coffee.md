
# Ambari Agent stop
 
    module.exports = []

## stop

    module.exports.push header: 'Ambari Agent # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'ambari-agent'
