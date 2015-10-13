
# Shinken Arbiter Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

    module.exports.push name: 'Shinken Arbiter # Start', label_true: 'STARTED', handler: ->
      @service
        srv_name: 'shinken-arbiter'
        action: 'start'