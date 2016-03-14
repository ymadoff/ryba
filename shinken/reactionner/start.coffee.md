
# Shinken Reactionner Start

    module.exports = header: 'Shinken Reactionner Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-reactionner'
