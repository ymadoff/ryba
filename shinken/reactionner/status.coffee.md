
# Shinken Reactionner Status

    module.exports =  header: 'Shinken Reactionner # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'shinken-reactionner'