
# OpenTSDB Stop

Stop the OpenTSDB service.

    module.exports = header: 'OpenTSDB Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'opentsdb'
        if_exists: '/etc/init.d/opentsdb'

## Stop Clean Logs

      @call header: 'Stop Clean Logs', label_true: 'CLEANED', handler: ->
        return unless @config.ryba.clean_logs
        @execute
          cmd: 'rm /var/log/opentsdb/*'
          code_skipped: 1
