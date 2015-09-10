
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the nagios service.

    module.exports.push name: 'Nagios # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'nagios'
        action: 'stop'

## Stop Clean Logs

    module.exports.push name: 'Nagios # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/nagios/*'
        code_skipped: 1
