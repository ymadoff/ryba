
# Shinken Poller

Gets checks from the scheduler, execute plugins or integrated poller modules and
send the results to the scheduler
Poller modules:

*   NRPE - Executes active data acquisition for Nagios Remote Plugin Executor agents
*   SNMP - Executes active data acquisition for SNMP enabled agents
*   CommandPipe - Receives passive status and performance data from check_mk script,
will not process commands

.
This module consumes proportionally to the cluster size. The limit for one poller
is approximatively 1000 checks/s

    module.exports = ->
      'configure': [
        'ryba/shinken/lib/configure'
        'ryba/shinken/poller/configure'
      ]
      'check':
        'ryba/shinken/poller/configure'
      'install': [
        'masson/core/yum'
        'masson/core/iptables'
        'masson/commons/docker'
        'ryba/shinken/lib/commons'
        #'ryba/mongodb'
        'ryba/shinken/poller/install'
        'ryba/shinken/poller/start'
        'ryba/shinken/poller/check'
      ]
      'start':
        'ryba/shinken/poller/start'
      'stop':
        'ryba/shinken/poller/stop'
      'prepare':
        'ryba/shinken/poller/prepare'
