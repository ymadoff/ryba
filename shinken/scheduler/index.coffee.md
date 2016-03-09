
# Shinken Scheduler

Plans the next run of host and service checks
Dispatches checks to the poller(s)
Calculates state and dependencies
Applies KPI triggers
Raises Notifications and dispatches them to the reactionner(s)
Updates the retention file (or other retention backends)
Sends broks (internal events of any kind) to the broker(s)

    module.exports = ->
      'configure': [
        'ryba/shinken/configure'
        'ryba/shinken/scheduler/configure'
      ]
      'check':
        'ryba/shinken/scheduler/check'
      'install': [
        'masson/core/yum'
        'masson/core/iptables'
        'ryba/shinken/commons'
        'ryba/shinken/scheduler/install'
        'ryba/shinken/scheduler/start'
        'ryba/shinken/scheduler/check'
      ]
      'start':
        'ryba/shinken/scheduler/start'        
      'status':
        'ryba/shinken/scheduler/status'
      'stop':
        'ryba/shinken/scheduler/stop'
