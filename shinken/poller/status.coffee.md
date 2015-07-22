
# Shinken Poller Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push name: 'Shinken Poller # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      next null, 'TODO'
