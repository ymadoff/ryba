
# Ambari Agent Start

Ambari Agent is started with the service's syntax command.

    module.exports = []

## Start

    module.exports.push name: 'Ambari Agent # Start', timeout: -1, label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service ambari-agent start'
        not_if_exists: '/var/run/ambari-agent/ambari-agent.pid'
      # @service_start
      #   name: 'ambari-agent'
