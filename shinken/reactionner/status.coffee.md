
# Shinken Reactionner Status

    module.exports =  header: 'Shinken Reactionner Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'shinken-reactionner'
