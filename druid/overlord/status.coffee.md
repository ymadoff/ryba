
# Druid Overlord Status

    module.exports = header: 'Druid Overlord Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'druid-overlord'
        if_exists: '/etc/init.d/druid-overlord'
