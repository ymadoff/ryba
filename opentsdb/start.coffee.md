
# OpenTSDB Start

    module.exports = header: 'OpenTSDB Start', label_true: 'STARTED', handler: ->
      @service.start name: 'opentsdb'
