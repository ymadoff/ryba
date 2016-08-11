
# Druid MiddleManager Status

    module.exports = header: 'Druid MiddleManager # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'druid-middlemanager'
        if_exists: '/etc/init.d/druid-middlemanager'
