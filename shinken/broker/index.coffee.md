
# Shinken Broker

Has multiple modules (usually running in their own processes). Gets broks from
the scheduler and forwards them to the broker modules.
Modules decide if they handle a brok depending on a brok's type
(log, initial service/host status, check result, begin/end downtime, ...).
Modules process the broks in many different ways.
Some of the modules are:

* webui - updates in-memory objects and provides a webserver for the native Shinken GUI
* livestatus - updates in-memory objects which can be queried using an API by GUIs like Thruk or Check_MK Multisite
* graphite - exports data to a Graphite database
* ndodb - updates an ndo database (MySQL or Oracle)
* simple_log - centralize the logs of all the Shinken processes
* status_dat - writes to a status.dat file which can be read by the classic cgi-based GUI

#

    module.exports = []
    module.exports.push 'ryba/shinken'
## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      broker = shinken.broker ?= {}
      # Additionnal modules to install
      broker.modules ?= {}
      webui = broker.modules['webui2'] ?= {}
      webui.version ?= "2.0.1"
      webui.source ?= "https://github.com/shinken-monitoring/mod-webui/archive/#{webui.version}.zip"
      webui.archive ?= "mod-webui-#{webui.version}"
      webui.modules ?= {}
      webui.config ?= {}
      webui.config.host ?= '0.0.0.0'
      webui.config.port ?= '7767'
      webui.config.auth_secret ?= 'rybashinken123'
      logs =  broker.modules['mongo-logs'] ?= {}
      logs.version = '1.0.2'
      graphite = broker.modules['graphite2'] ?= {}
      graphite.version = '2.1.0'
      graphite.source ?= "https://github.com/shinken-monitoring/mod-graphite/archive/#{graphite.version}.zip"
      graphite.archive ?= "mod-graphite-#{graphite.version}"
      ## Auto discovery
      configmod = (name, mod) =>
        if mod.version?
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.zip"
          mod.archive ?= "mod-#{name}-#{mod.version}"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of broker.modules then configmod name, mod
      # CONFIG
      broker.config ?= {}
      broker.config.port ?= 7772
      broker.config.modules = [broker.config.modules] if typeof broker.config.modules is 'string'
      broker.config.modules ?= Object.keys broker.modules

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/broker/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/broker/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/broker/install'
      'ryba/shinken/broker/start'
      # 'ryba/shinken/broker/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/broker/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/broker/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/broker/stop'
