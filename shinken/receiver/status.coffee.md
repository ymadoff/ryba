
# Shinken Receiver Status

    module.exports =  header: 'Shinken Receiver # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'shinken-receiver'