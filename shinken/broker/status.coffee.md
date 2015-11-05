
# Shinken Broker Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push header: 'Shinken Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {broker} = @config.ryba.shinken
      # 'TODO'
