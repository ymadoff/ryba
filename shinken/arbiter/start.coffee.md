
# Shinken Arbiter Start

    module.exports = header: 'Shinken Arbiter Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-arbiter'
