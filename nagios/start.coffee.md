
# Nagios Start

    module.exports = header: 'Nagios Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'nagios'
        code_stopped: 1
