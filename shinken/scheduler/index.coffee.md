
# Shinken Scheduler

Plans the next run of host and service checks
Dispatches checks to the poller(s)
Calculates state and dependencies
Applies KPI triggers
Raises Notifications and dispatches them to the reactionner(s)
Updates the retention file (or other retention backends)
Sends broks (internal events of any kind) to the broker(s)

    module.exports = []
    module.exports.push 'ryba/shinken'

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      scheduler = shinken.scheduler ?= {}
      # Additionnal Modules to install
      scheduler.modules ?= {}
      # Config
      scheduler.config ?= {}
      scheduler.config.port ?= 7768 # Propriété non honorée !!
      scheduler.config.spare ?= '0'
      scheduler.config.realm ?= 'All'
      scheduler.config.modules = [scheduler.config.modules] if typeof scheduler.config.modules is 'string'
      scheduler.config.modules ?= Object.keys scheduler.modules
      scheduler.config.use_ssl ?= shinken.config.use_ssl
      scheduler.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check

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
