
# Shinken Poller Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Poller service.

    module.exports.push name: 'Shinken Poller # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'shinken-poller'
        action: 'stop'

## Clean Logs

    module.exports.push name: 'Shinken Poller # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
