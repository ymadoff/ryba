
# Tranquility Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'Tranquility Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'tranquility'
