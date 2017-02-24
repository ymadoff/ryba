
# Shinken Arbiter Stop

    module.exports = header: 'Shinken Arbiter Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-arbiter'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, handler: ->
        @system.execute
          cmd: 'rm /var/log/shinken/arbiterd*'
          code_skipped: 1
