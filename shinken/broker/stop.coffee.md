
# Shinken Broker Stop

    module.exports = header: 'Shinken Broker Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'shinken-broker'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, handler: ->
        @execute
          cmd: 'rm /var/log/shinken/brokerd*'
          code_skipped: 1
