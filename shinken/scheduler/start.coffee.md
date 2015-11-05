
# Shinken Scheduler Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Stop the Shinken Scheduler service.

    module.exports.push header: 'Shinken Scheduler # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-scheduler'
