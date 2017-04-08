
# Shinken Scheduler Stop

    module.exports = header: 'Shinken Scheduler Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-scheduler'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/schedulerd*'
          code_skipped: 1
