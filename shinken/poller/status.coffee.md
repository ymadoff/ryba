
# Shinken Poller Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push header: 'Shinken Poller # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      plugins = null
      # TODO
