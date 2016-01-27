
# Shinken Reactionner

Gets notifications and eventhandlers from the scheduler, executes plugins/scripts
and sends the results to the scheduler.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      reactionner = shinken.reactionner ?= {}
      # Additionnal Modules to install
      reactionner.modules ?= {}
      # Config
      reactionner.config ?={}
      reactionner.config.port ?= 7769
      reactionner.config.spare ?= '0'
      reactionner.config.realm ?= 'All'
      reactionner.config.modules = [reactionner.config.modules] if typeof reactionner.config.modules is 'string'
      reactionner.config.modules ?= Object.keys reactionner.modules
      reactionner.config.tags = [reactionner.config.tags] if typeof reactionner.config.tags is 'string'
      reactionner.config.tags ?= []
      reactionner.config.use_ssl ?= shinken.config.use_ssl
      reactionner.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/reactionner/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/reactionner/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/reactionner/install'
      'ryba/shinken/reactionner/start'
      'ryba/shinken/reactionner/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/reactionner/start'

    module.exports.push commands: 'status', modules: 'ryba/shinken/reactionner/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/reactionner/stop'
