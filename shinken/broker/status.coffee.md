
# Shinken Broker Status

    module.exports =  header: 'Shinken Broker Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'shinken-broker'
