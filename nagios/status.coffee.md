
# Nagios Status

    module.exports = name: 'Nagios Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'nagios'
        code_stopped: 1
