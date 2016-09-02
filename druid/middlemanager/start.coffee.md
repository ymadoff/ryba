
# Druid MiddleManager Start

    module.exports = header: 'Druid MiddleManager # Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'druid-middlemanager'
