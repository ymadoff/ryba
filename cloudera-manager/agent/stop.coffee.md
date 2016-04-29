
# Cloudera Manager Agent stop

    module.exports = header: 'Cloudera Manager Agent Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'cloudera-scm-agent'
