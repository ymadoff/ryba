
# Druid Historical Status

    module.exports = header: 'Druid Historical # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'druid-historical'
        if_exists: '/etc/init.d/druid-historical'
