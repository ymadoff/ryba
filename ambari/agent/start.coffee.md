
# Ambari Agent Start

Ambari Agent is started with the service's syntax command.

    module.exports = header: 'Ambari Agent Start', timeout: -1, label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service ambari-agent start'
        unless_exists: '/var/run/ambari-agent/ambari-agent.pid'
      # @service_start
      #   name: 'ambari-agent'
