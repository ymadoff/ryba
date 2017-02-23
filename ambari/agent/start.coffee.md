
# Ambari Agent Start

Ambari Agent is started with the service's syntax command.

    module.exports = header: 'Ambari Agent Start', timeout: -1, label_true: 'STARTED', handler: ->
      @system.execute
        cmd: 'service ambari-agent start'
        unless_exists: '/var/run/ambari-agent/ambari-agent.pid'
      # @service.start
      #   name: 'ambari-agent'
