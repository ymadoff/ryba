
# OpenTSDB Start

    module.exports = header: 'OpenTSDB Start', label_true: 'STARTED', handler: ->
      @service_start name: 'opentsdb'
