
# Druid Historical Start

    module.exports = header: 'Druid Historical # Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'druid-historical'
