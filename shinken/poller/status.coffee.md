
# Shinken Poller Status

    module.exports =  header: 'Shinken Poller Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'shinken-poller'
