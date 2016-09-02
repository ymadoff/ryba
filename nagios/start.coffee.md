
# Nagios Start

    module.exports = header: 'Nagios Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'nagios'
        code_stopped: 1
