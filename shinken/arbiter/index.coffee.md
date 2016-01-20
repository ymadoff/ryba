
# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler. Host the WebUI.

    module.exports = []
    module.exports.push 'ryba/shinken'

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      # Arbiter specific configuration
      arbiter = shinken.arbiter ?= {}
      # Auto-discovery of Modules
      arbiter.modules ?= {}
      configmod = (name, mod) =>
        if mod.version?
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
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
      arbiter.config.distributed ?= ctx.hosts_with_module('ryba/shinken/arbiter').length > 1
      arbiter.config.hostname ?= ctx.config.host
      arbiter.config.user = shinken.user.name
      arbiter.config.group = shinken.group.name
      arbiter.config.host ?= '0.0.0.0'
      arbiter.config.use_ssl ?= shinken.config.use_ssl
      arbiter.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
      # Kerberos
      #shinken.keytab ?= '/etc/security/keytabs/shinken.service.keytab'
      #shinken.principal ?= "shinken/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      #shinken.plugin_dir ?= '/usr/lib64/shinken/plugins'
      shinken.config.users ?= {}
      if Object.keys(shinken.config.users).length is 0
        shinken.config.users.shinken =
          password: 'shinken123'
          alias: 'Shinken Admin'
          email: ''
          admin: true
      # WebUI Groups
      shinken.config.groups ?= {}
      if Object.keys(shinken.config.groups).length is 0
        shinken.config.groups.admins =
          alias: 'Shinken Administrators'
          members: ['shinken']

Monitoring Configuration

      shinken.config.servicegroups ?= {}
      shinken.config.services ?= {}
      shinken.config.hostgroups ?= {}
      shinken.config.hosts ?= {}
      shinken.config.realms ?= {}
      shinken.config.contactgroups ?= {}
      shinken.config.contacts ?= {}
      shinken.config.dependencies ?= {}
      shinken.config.escalations ?= {}
      timeperiods = shinken.config.timeperiods ?= {}
      # Servicegroups
      configure.servicegroups.call ctx
      # From exports files (HostGroups, Host, Realms)
      configure.from_exports.call ctx
      # ContactGroups
      
      # Contacts
      # Time period
      timeperiods['24x7'] ?= {}
      timeperiods['24x7'].alias ?= 'Everytime'
      timeperiods['24x7'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        timeperiods['24x7'].time[day] ?= '00:00-24:00'
      timeperiods.none ?= {}
      timeperiods.none.alias ?= 'Never'
      timeperiods.none.time = {}
      # Normalize
      configure.normalize.call ctx

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/arbiter/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/arbiter/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/arbiter/install'
      'ryba/shinken/arbiter/start'
      'ryba/shinken/arbiter/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/arbiter/start'

    module.exports.push commands: 'status', modules: 'ryba/shinken/arbiter/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/arbiter/stop'

## Dependencies

    configure = require './lib/configure'