
# MongoDB Shard Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    
## Stop

Stop the MongoDB services.

    module.exports.push name: 'MongoDB Shard # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: "mongod" ## "mongod --shardsrv #{mongos_hosts} --logappend"
      
## Clean Logs

    module.exports.push name: 'MongoDB Shard # Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      {mongodb} = @config.ryba
      @execute
        cmd: "rm #{mongodb.log_dir}/*"
        code_skipped: 1
