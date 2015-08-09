
# Shinken Poller

Gets checks from the scheduler, execute plugins or integrated poller modules and
send the results to the scheduler
Poller modules:

*   NRPE - Executes active data acquisition for Nagios Remote Plugin Executor agents
*   SNMP - Executes active data acquisition for SNMP enabled agents
*   CommandPipe - Receives passive status and performance data from check_mk script,
will not process commands

.
This module consumes proportionally to the cluster size. The limit for one poller
is approximatively 1000 checks/s

## Dependencies

    module.exports = []

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken, realm} = ctx.config.ryba
      poller = ctx.config.ryba.shinken.poller ?= {}
      # Kerberos
      poller.krb5_user ?= {}
      poller.krb5_user.principal ?= "#{shinken.user.name}/#{ctx.config.host}@#{realm}"
      poller.krb5_user.keytab ?= "/etc/security/keytabs/shinken-poller.service.keytab"
      # Python
      poller.python ?= {}
      poller.python.archive ?= 'Python-2.7.9'
      poller.python.source ?= 'https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz'
      # Python modules to install
      poller.python_modules ?= {}
      poller.python_modules.requests ?= {}
      poller.python_modules.requests.archive ?= 'requests-2.5.1'
      poller.python_modules.requests.source ?= 'https://github.com/kennethreitz/requests/archive/v2.5.1.tar.gz'
      poller.python_modules.kerberos ?= {}
      poller.python_modules.kerberos.archive ?= 'kerberos-1.1.1'
      poller.python_modules.kerberos.source ?= 'https://pypi.python.org/packages/source/k/kerberos/kerberos-1.1.1.tar.gz'
      poller.python_modules.requests_kerberos ?= {}
      poller.python_modules.requests_kerberos.archive ?= 'requests-kerberos-0.7.0'
      poller.python_modules.requests_kerberos.source ?= 'https://github.com/requests/requests-kerberos/archive/0.7.0.tar.gz'
      # Additionnal Modules to install
      poller.modules ?= {}
      # Config
      poller.config ?= {}
      poller.config.port ?= 7771
      poller.config.modules = [poller.config.modules] if typeof poller.config.modules is 'string'
      poller.config.modules ?= Object.getOwnPropertyNames poller.modules

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/poller/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/poller/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/poller/install'
      'ryba/shinken/poller/start'
      # 'ryba/shinken/poller/check' # Must be executed before start
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/poller/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/poller/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/poller/stop'
