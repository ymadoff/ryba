
# ActiveMQ Server Stop

ActiveMQ Server is started through service command.Which is wrapper around
the docker container.

    module.exports = header: 'ActiveMQ Server Stop', label_true: 'STARTED', handler: ->
      {activemq} = @config.ryba
      @service.stop
        header: 'Stop service'
        name: 'activemq'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', handler: ->
        return unless @config.ryba.clean_logs
        @system.execute
          cmd: "rm #{activemq.log_dir}/*"
          code_skipped: 1
