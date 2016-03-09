
# Shinken Broker Start

    module.exports = header: 'Shinken Broker Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-broker'
