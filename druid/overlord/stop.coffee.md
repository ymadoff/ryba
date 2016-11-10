
# Druid Overlord Stop

    module.exports = header: 'Druid Overlord Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service.stop
        name: 'druid-overlord'
        if_exists: '/etc/init.d/druid-overlord'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{druid.log_dir}/overlord.log"
        code_skipped: 1
