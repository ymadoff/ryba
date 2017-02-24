
# MongoDB Routing Server Stop

    module.exports = header: 'MongoDB Routing Server Stop', label_true: 'STOPPED', handler: ->
      {router} = @config.ryba.mongodb

## Stop

Stop the MongoDB Routing Server service.

      @service.stop
        header: 'Stop service'
        name: 'mongod-router-server'

## Clean Logs

      @call ->
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: @config.ryba.clean_logs
        handler: ->
          @system.execute
            cmd: "rm #{router.config.logpath}"
            code_skipped: 1
