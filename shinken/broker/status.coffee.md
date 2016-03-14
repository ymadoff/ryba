
# Shinken Broker Status

    module.exports =  header: 'Shinken Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'shinken-broker'