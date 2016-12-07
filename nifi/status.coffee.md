
# Apache NiFi Status

    module.exports = header: 'NiFi Status', label_true: 'STARTED',label_true: 'STOPPED', handler: ->
      @service.status
        name: 'nifi'
        code_stopped: 1
