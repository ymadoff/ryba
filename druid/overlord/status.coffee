
# Druid Overlord Status

    module.exports = header: 'Druid Overlord # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'druid-overlord'
        if_exists: '/etc/init.d/druid-overlord'
