
# Shinken Arbiter Start

    module.exports = header: 'Shinken Arbiter Start', label_true: 'STARTED', handler: ->
      @service.start name: 'shinken-arbiter'
