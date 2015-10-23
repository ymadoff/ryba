
# Shinken Arbiter Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push name: 'Shinken Arbiter # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      plugin = null
      # TODO
