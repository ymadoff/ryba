
# Ambari Agent stop
 
    module.exports = []

## stop

    module.exports.push name: 'Ambari Agent # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service_stop
          name: 'ambari-agent'
