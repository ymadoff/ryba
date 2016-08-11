
# Druid MiddleManager Stop

    module.exports = header: 'Druid MiddleManager # Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service_stop
        name: 'druid-middlemanager'
        if_exists: '/etc/init.d/druid-middlemanager'
