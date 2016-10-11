
# Druid MiddleManager Stop

    module.exports = header: 'Druid MiddleManager # Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service.stop
        name: 'druid-middlemanager'
        if_exists: '/etc/init.d/druid-middlemanager'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{druid.log_dir}/middleManager.log"
        code_skipped: 1
