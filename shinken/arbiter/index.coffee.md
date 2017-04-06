
# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
      configure: [
        'ryba/shinken/lib/configure'
        'ryba/shinken/arbiter/configure'
      ]
      commands:
        'check':
          'ryba/shinken/arbiter/check'
        'install': [
          'masson/core/yum'
          'masson/core/iptables'
          'ryba/shinken/lib/commons'
          'ryba/shinken/arbiter/install'
          'ryba/shinken/arbiter/start'
          'ryba/shinken/arbiter/check'
        ]
        'start':
          'ryba/shinken/arbiter/start'
        'status':
          'ryba/shinken/arbiter/status'
        'stop':
          'ryba/shinken/arbiter/stop'
