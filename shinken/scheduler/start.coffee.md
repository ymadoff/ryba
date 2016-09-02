
# Shinken Scheduler Start

    module.exports = header: 'Shinken Scheduler Start', label_true: 'STARTED', handler: ->
      @service.start name: 'shinken-scheduler'
