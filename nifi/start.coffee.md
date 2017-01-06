
# NiFi Start

    module.exports = header: 'NiFi Start', label_true: 'STARTED', handler: ->
      @service.start name: 'nifi'
