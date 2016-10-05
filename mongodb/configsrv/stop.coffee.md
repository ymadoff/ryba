
# MongoDB Config Server Stop

    module.exports = header: 'MongoDB Config Server Stop', label_true: 'STOPPED', handler: ->
      {configsrv} = @config.ryba.mongodb

## Stop

Stop the MongoDB Config Server service.

      @service.stop name: 'mongodb-config-server'

## Clean Logs

      @call
        if:  @config.ryba.clean_logs
        header: 'MongoDB Config Server # Clean Logs'
        label_true: 'CLEANED'
        handler: ->
          @execute
            cmd: "rm #{configsrv.config.systemLog.path}"
            code_skipped: 1
