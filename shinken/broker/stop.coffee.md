
# Shinken Broker Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Broker service.

    module.exports.push name: 'Shinken Broker # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'shinken-broker'
        action: 'stop'

## Clean Logs

    module.exports.push name: 'Shinken Broker # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
