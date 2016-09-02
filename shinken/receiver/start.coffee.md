
# Shinken Receiver Start

    module.exports = header: 'Shinken Receiver Start', label_true: 'STARTED', handler: ->
      @service.start name: 'shinken-receiver'
