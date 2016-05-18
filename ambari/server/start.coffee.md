
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Start', timeout: -1, label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service ambari-server start'
        unless_exists: '/var/run/ambari-server/ambari-server.pid'
      # @service_start
      #   name: 'ambari-server'
