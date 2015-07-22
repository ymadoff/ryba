
# Shinken Scheduler Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push name: 'Shinken Scheduler # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      next null, 'TODO'
