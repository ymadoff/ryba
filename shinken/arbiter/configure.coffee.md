
# Shinken Arbiter Configure

    module.exports = ->
      {shinken} = @config.ryba
      # Arbiter specific configuration
      arbiter = shinken.arbiter ?= {}
      # Auto-discovery of Modules
      arbiter.modules ?= {}
      configmod = (name, mod) =>
        if mod.version?
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
          mod.config_file ?= "#{name}.cfg"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of arbiter.modules then configmod name, mod
      # Config
      arbiter.config ?= {}
      arbiter.config.port ?= 7770
      arbiter.config.spare ?= '0'
      arbiter.config.modules = [arbiter.config.modules] if typeof arbiter.config.modules is 'string'
      arbiter.config.modules ?= Object.keys arbiter.modules
      arbiter.config.distributed ?= @contexts('ryba/shinken/arbiter').length > 1
      arbiter.config.hostname ?= @config.host
      arbiter.config.user = shinken.user.name
      arbiter.config.group = shinken.group.name
      arbiter.config.host ?= '0.0.0.0'
      arbiter.config.use_ssl ?= shinken.config.use_ssl
      arbiter.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
      shinken.config.users ?= 
        shinken:
          password: 'shinken123'
          alias: 'Shinken Admin'
          email: ''
          admin: true
      # WebUI Groups
      shinken.config.groups ?=
        admins:
          alias: 'Shinken Administrators'
          members: ['shinken']
