
# Shinken Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Broker service.

    module.exports.push name: 'Shinken Broker # Start', label_true: 'STARTED', handler: ->
      @service
        srv_name: 'shinken-broker'
        action: 'start'
