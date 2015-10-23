
# Shinken Arbiter Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Stop

Stop the Shinken Arbiter service.

    module.exports.push name: 'Shinken Arbiter # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'shinken-arbiter'
        action: 'stop'

## Clean Logs

    module.exports.push name: 'Shinken Arbiter # Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/shinken/*'
        code_skipped: 1
