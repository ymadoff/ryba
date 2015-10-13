
# Shinken Receiver Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Receiver service.

    module.exports.push name: 'Shinken Receiver # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'shinken-receiver'
        action: 'stop'

## Clean Logs

    module.exports.push name: 'Shinken Receiver # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless ctx.config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
