
# Shinken Broker Stop

    module.exports = header: 'Shinken Broker Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-broker'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, handler: ->
        @system.execute
          cmd: 'rm /var/log/shinken/brokerd*'
          code_skipped: 1
