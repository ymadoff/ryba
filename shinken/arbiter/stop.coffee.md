
# Shinken Arbiter Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Arbiter service.

    module.exports.push header: 'Shinken Arbiter # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'shinken-arbiter'

## Clean Logs

    module.exports.push header: 'Shinken Arbiter # Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
