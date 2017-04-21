
# Shinken Scheduler Configure

    module.exports = ->
      {shinken} = @config.ryba
      scheduler = shinken.scheduler ?= {}
      # Additionnal Modules to install
      scheduler.modules ?= {}
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
      for name, mod of scheduler.modules then configmod name, mod
      # Config
      scheduler.config ?= {}
      scheduler.config.port ?= 7768 # Propriété non honorée !!
      scheduler.config.spare ?= '0'
      scheduler.config.realm ?= 'All'
      scheduler.config.modules = [scheduler.config.modules] if typeof scheduler.config.modules is 'string'
      scheduler.config.modules ?= Object.keys scheduler.modules
      scheduler.config.use_ssl ?= shinken.config.use_ssl
      scheduler.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
