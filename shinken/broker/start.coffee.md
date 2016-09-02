
# Shinken Broker Start

    module.exports = header: 'Shinken Broker Start', label_true: 'STARTED', handler: ->
      @service.start name: 'shinken-broker'
