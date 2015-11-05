
# Shinken Scheduler Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Scheduler service.

    module.exports.push header: 'Shinken Scheduler # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'shinken-scheduler'

## Clean Logs

    module.exports.push header: 'Shinken Scheduler # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
