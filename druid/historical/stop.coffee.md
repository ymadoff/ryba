
# Druid Historical Stop

    module.exports = header: 'Druid Historical # Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service.stop
        name: 'druid-historical'
        if_exists: '/etc/init.d/druid-historical'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{druid.log_dir}/historical.log"
        code_skipped: 1
