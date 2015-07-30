
# Shinken Receiver (optional)

Receives data passively from local or remote protocols. Passive data reception
that is buffered before forwarding to the appropriate Scheduler (or receiver for global commands).
Allows to set up a "farm" of Receivers to handle a high rate of incoming events.
Modules for receivers:

* NSCA - NSCA protocol receiver
* Collectd - Receive performance data from collectd via the network
* CommandPipe - Receive commands, status updates and performance data
* TSCA - Apache Thrift interface to send check results using a high rate buffered TCP connection directly from programs
* Web Service - A web service that accepts http posts of check results (beta)

## Dependencies

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      receiver = ctx.config.ryba.shinken.receiver ?= {}
      # Additionnal Modules to install
      receiver.modules ?= {}
      # Config
      receiver.config ?= {}
      receiver.config.port ?= 7773
      receiver.config.modules = [receiver.config.modules] if typeof receiver.config.modules is 'string'
      receiver.config.modules ?= Object.getOwnPropertyNames receiver.modules

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/receiver/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/receiver/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/receiver/install'
      'ryba/shinken/receiver/start'
      # 'ryba/shinken/receiver/check' # Must be executed before start
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/receiver/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/receiver/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/receiver/stop'
