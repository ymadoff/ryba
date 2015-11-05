
# MongoDB Config Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    
## Stop

Stop the MongoDB Config Server service.

    module.exports.push header: 'MongoDB ConfigSrv # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'mongodb-configsrv'

## Clean Logs

    module.exports.push header: 'MongoDB ConfigSrv # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      {configsrv} = @config.ryba.mongodb
      @execute
        cmd: "rm #{configsrv.config.logpath}"
        code_skipped: 1
