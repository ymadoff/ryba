
# Shinken Receiver Start

    module.exports = header: 'Shinken Receiver Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-receiver'
