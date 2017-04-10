
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

    module.exports =
      use:
        yum: implicit: true, module: 'masson/core/yum'
        iptables: implicit: true, module: 'masson/core/iptables'
        docker: implicit: true, module: 'masson/commons/docker'
      configure: [
        'ryba/shinken/lib/configure'
        'ryba/shinken/poller/configure'
      ]
      commands:
        'check':
          'ryba/shinken/poller/configure'
        'install': [
          'ryba/shinken/lib/commons'
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
