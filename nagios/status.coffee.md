
# Nagios Status

    module.exports = name: 'Nagios Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'nagios'
        code_stopped: 1
