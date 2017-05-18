
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Standalone Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'ambari-server'
