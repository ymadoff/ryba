
# Shinken Reactionner

Gets notifications and eventhandlers from the scheduler, executes plugins/scripts
and sends the results to the scheduler.

    module.exports = []

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      shinken.reactionner ?= {}
      shinken.reactionner.config ?={}
      shinken.reactionner.config.port ?= 7769 # Propriété non honorée !!
      shinken.reactionner.config.modules = [shinken.reactionner.config.modules] if typeof shinken.reactionner.config.modules is 'string'
      shinken.reactionner.config.modules ?= []

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/reactionner/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/reactionner/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/reactionner/install'
      'ryba/shinken/reactionner/start'
    # 'ryba/shinken/reactionner/check' # Must be executed before start
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/reactionner/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/reactionner/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/reactionner/stop'
