
# Shinken Broker Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/mongodb/start'

## Start

Start the Shinken Broker service.

    module.exports.push name: 'Shinken Broker # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-broker'
        action: 'start'
      .then next
