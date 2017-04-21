
# Shinken Reactionner Configure

    module.exports = ->
      {shinken} = @config.ryba
      reactionner = shinken.reactionner ?= {}
      # Additionnal Modules to install
      reactionner.modules ?= {}
      configmod = (name, mod) =>
        if mod.version?
          mod.type ?= name
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
          mod.config_file ?= "#{name}.cfg"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of reactionner.modules then configmod name, mod
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
