
# OpenTSDB Status

    module.exports = header: 'OpenTSDB Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'opentsdb'
