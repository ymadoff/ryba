
# Shinken Receiver Status

    module.exports =  header: 'Shinken Receiver Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'shinken-receiver'
