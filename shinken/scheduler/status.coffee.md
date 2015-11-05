
# Shinken Scheduler Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push header: 'Shinken Scheduler # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      todo = null
      # 'TODO'
