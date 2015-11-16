
# Shinken Receiver Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Receiver service.

    module.exports.push header: 'Shinken Receiver # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'shinken-receiver'

## Clean Logs

    module.exports.push header: 'Shinken Receiver # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
