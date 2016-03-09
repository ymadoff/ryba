
# Shinken Scheduler Configure

    module.exports = handler: ->
      {shinken} = @config.ryba
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