
# MongoDB Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the MongoDB service.

    module.exports.push header: 'MongoDB Server # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'mongod'
        action: 'stop'

## Stop Clean Logs

    module.exports.push header: 'MongoDB Server # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      {mongodb} = @config.ryba
      @execute
        cmd: "rm #{mongodb.log_dir}/*"
        code_skipped: 1
