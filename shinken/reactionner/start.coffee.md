
# Shinken Reactionner Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Reactionner service.

    module.exports.push header: 'Shinken Reactionner # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-reactionner'
