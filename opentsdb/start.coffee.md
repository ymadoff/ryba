
# OpenTSDB Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'OpenTSDB # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'opentsdb'