
# Shinken Scheduler

Plans the next run of host and service checks
Dispatches checks to the poller(s)
Calculates state and dependencies
Applies KPI triggers
Raises Notifications and dispatches them to the reactionner(s)
Updates the retention file (or other retention backends)
Sends broks (internal events of any kind) to the broker(s)

    module.exports = []

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      shinken.scheduler ?= {}
      shinken.scheduler.config ?= {}
      shinken.scheduler.config.port ?= 7768 # Propriété non honorée !!
      shinken.scheduler.config.modules = [shinken.scheduler.modules] if typeof shinken.scheduler.modules is 'string'
      shinken.scheduler.config.modules ?= []

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/scheduler/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/scheduler/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/scheduler/install'
      'ryba/shinken/scheduler/start'
      'ryba/shinken/scheduler/check' # Must be executed before start
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/scheduler/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/scheduler/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/scheduler/stop'
