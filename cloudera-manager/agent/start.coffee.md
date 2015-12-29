# Cloudera Manager Agent Start

Cloudera Manager Agent is started with the service's syntax command.

    module.exports = []

## Start

    module.exports.push name: 'Cloudera Manager Agent # Start', timeout: -1, label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service cloudera-scm-agent start'
        # not_if_exists: '/var/run/ambari-agent/ambari-agent.pid'
