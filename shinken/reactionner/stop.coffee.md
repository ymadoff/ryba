
# Shinken Reactionner Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Reactionner service.

    module.exports.push name: 'Shinken Reactionner # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'shinken-reactionner'
        action: 'stop'

## Clean Logs

    module.exports.push name: 'Shinken Reactionner # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless ctx.config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
