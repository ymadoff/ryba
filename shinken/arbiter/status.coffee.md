
# Shinken Arbiter Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push header: 'Shinken Arbiter # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {arbiter} = @config.ryba.shinken
      # TODO
