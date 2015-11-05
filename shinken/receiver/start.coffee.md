
# Shinken Receiver Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Receiver service.

    module.exports.push header: 'Shinken Receiver # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-receiver'
