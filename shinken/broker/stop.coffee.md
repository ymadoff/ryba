
# Shinken Broker Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Broker service.

    module.exports.push header: 'Shinken Broker # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'shinken-broker'

## Clean Logs

    module.exports.push header: 'Shinken Broker # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
