
# Shinken Poller Stop

    module.exports = header: 'Shinken Poller Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-poller'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, handler: ->
        @execute
          cmd: 'rm /var/log/shinken/pollerd*'
          code_skipped: 1
