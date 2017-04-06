
# Shinken Reactionner

Gets notifications and eventhandlers from the scheduler, executes plugins/scripts
and sends the results to the scheduler.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
      configure: [
        'ryba/shinken/lib/configure'
        'ryba/shinken/reactionner/configure'
      ]
      commands:
        'check':
          'ryba/shinken/reactionner/check'
        'install': [
          'masson/core/yum'
          'masson/core/iptables'
          'ryba/shinken/lib/commons'
          'ryba/shinken/reactionner/install'
          'ryba/shinken/reactionner/start'
          'ryba/shinken/reactionner/check'
        ]
        'start':
          'ryba/shinken/reactionner/start'        
        'status':
          'ryba/shinken/reactionner/status'
        'stop':
          'ryba/shinken/reactionner/stop'
