
# Shinken Scheduler Status

    module.exports =  header: 'Shinken Scheduler # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'shinken-scheduler'