
# Druid Broker Status

    module.exports = header: 'Druid Broker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'druid-broker'
        if_exists: '/etc/init.d/druid-broker'
