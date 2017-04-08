
# OpenTSDB Stop

Stop the OpenTSDB service.

    module.exports = header: 'OpenTSDB Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'opentsdb'
        if_exists: '/etc/init.d/opentsdb'

## Stop Clean Logs

      @call header: 'Stop Clean Logs', label_true: 'CLEANED', ->
        return unless @config.ryba.clean_logs
        @system.execute
          cmd: 'rm /var/log/opentsdb/*'
          code_skipped: 1
