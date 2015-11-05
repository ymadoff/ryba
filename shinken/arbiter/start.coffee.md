
# Shinken Arbiter Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

    module.exports.push header: 'Shinken Arbiter # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-arbiter'
