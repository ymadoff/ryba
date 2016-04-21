
# NiFi Manager Start

    module.exports = header: 'NiFi Manager Start', label_true: 'STARTED', handler: ->
      @service_start name: 'nifi-manager'
