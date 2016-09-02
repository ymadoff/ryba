
# Apache NiFi Manager Status

    module.exports = header: 'NiFi Manager Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'nifi-manager'
