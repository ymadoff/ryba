
# Druid Coordinator Stop

    module.exports = header: 'Druid Coordinator # Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service_stop
        name: 'druid-coordinator'
        if_exists: '/etc/init.d/druid-coordinator'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{druid.log_dir}/coordinator.log"
        code_skipped: 1
