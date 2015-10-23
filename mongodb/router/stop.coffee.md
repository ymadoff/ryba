
# MongoDB Routing Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    
## Stop

Stop the MongoDB Routing Server service.

    module.exports.push name: 'MongoDB Routing Server # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'mongos'

## Clean Logs

    module.exports.push name: 'MongoDB Routing Server # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      {router} = @config.ryba.mongodb
      @execute
        cmd: "rm #{router.config.logpath}"
        code_skipped: 1
