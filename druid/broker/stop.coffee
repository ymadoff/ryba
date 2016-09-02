
# Druid Broker Stop

    module.exports = header: 'Druid Broker # Stop', label_true: 'STOPPED', handler: ->
      {druid, clean_logs} = @config.ryba
      @service.stop
        name: 'druid-broker'
        if_exists: '/etc/init.d/druid-broker'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{druid.log_dir}/broker.log"
        code_skipped: 1
