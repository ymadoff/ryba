
# Apache NiFi Manager Status

    module.exports = header: 'NiFi Manager Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'nifi-manager'
