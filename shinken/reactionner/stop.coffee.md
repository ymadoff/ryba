
# Shinken Reactionner Stop

    module.exports = header: 'Shinken Reactionner Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'shinken-reactionner'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', if: @config.ryba.clean_logs, handler: ->
        @system.execute
          cmd: 'rm /var/log/shinken/reactionnerd*'
          code_skipped: 1
