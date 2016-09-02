
# Apache NiFi Manager Start

    module.exports = header: 'NiFi Manager Start', label_true: 'STARTED', handler: ->
      @service.start name: 'nifi-manager'
