
# Shinken Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Broker service.

    module.exports.push header: 'Shinken Broker # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-broker'
