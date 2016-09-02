
# Druid Overlord Start

    module.exports = header: 'Druid Overlord # Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'druid-overlord'
