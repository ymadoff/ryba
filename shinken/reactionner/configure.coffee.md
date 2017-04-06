
# Shinken Reactionner Configure

    module.exports = ->
      {shinken} = @config.ryba
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
