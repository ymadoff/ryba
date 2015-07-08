
# Shinken Arbiter Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

    module.exports.push name: 'Shinken Arbiter # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken-arbiter'
        action: 'start'
      .then next
