
# Apache NiFi Manager Status

    module.exports = header: 'NiFi Manager Status', label_true: 'STARTED',label_true: 'STOPPED', handler: ->
      @service.status
        name: 'nifi-manager'
        code_stopped: 1
