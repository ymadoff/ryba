# Cloudera Manager Server Start

Cloudera Manager Agent is started with the service's syntax command.

    module.exports = []

## Start

    module.exports.push name: 'Cloudera Manager Server # Start', timeout: -1, label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service cloudera-scm-server start'
        # not_if_exists: '/var/run/ambari-agent/ambari-agent.pid'
