
# NiFi Stop

    module.exports = header: 'NiFi Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'nifi'
