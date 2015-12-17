
# OpenTSDB Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the OpenTSDB service.

    module.exports.push header: 'OpenTSDB # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'opentsdb'

## Stop Clean Logs

    module.exports.push header: 'OpenTSDB # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/opentsdb/*'
        code_skipped: 1
