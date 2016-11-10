
# Druid Coordinator Status

    module.exports = header: 'Druid Coordinator Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'druid-coordinator'
        if_exists: '/etc/init.d/druid-coordinator'
