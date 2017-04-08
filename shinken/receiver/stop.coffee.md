
# Shinken Receiver Stop

    module.exports = header: 'Shinken Receiver Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-receiver'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/receiverd*'
          code_skipped: 1
