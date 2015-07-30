
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

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      broker = ctx.config.ryba.shinken.broker ?= {}
      # Additionnal modules to install
      broker.modules ?= {}
      webui = broker.modules['webui'] ?= {}
      webui.source ?= 'https://github.com/shinken-monitoring/mod-webui/archive/1.0.zip'
      webui.archive ?= 'mod-webui-1.0'
      webui.config ?= {}
      webui.config.host ?= '0.0.0.0'
      webui.config.port ?= 7767
      webui.config.auth_secret ?= 'rybashinken'
      webui.config.modules = [webui.config.modules] if typeof webui.config.modules is 'string'
      webui.config.modules ?= ['auth-cfg-password', 'mongodb']
      auth = broker.modules['auth-cfg-password'] ?= {}
      auth.source ?= 'https://github.com/shinken-monitoring/mod-auth-cfg-password/archive/2.0.1.zip'
      auth.archive ?= 'mod-auth-cfg-password-2.0.1'
      mongodb = broker.modules['mongodb'] ?= {}
      mongodb.source ?= 'https://github.com/shinken-monitoring/mod-mongodb/archive/1.0.1.zip'
      mongodb.archive ?= 'mod-mongodb-1.0.1'
      ## CONFIG
      broker.config ?= {}
      broker.config.port ?= 7772
      broker.config.modules = [broker.config.modules] if typeof broker.config.modules is 'string'
      broker.config.modules ?= ['webui']
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
