
# MongoDB Shard Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the MongoDB services.

    module.exports.push name: 'MongoDB Shard # Stop Shard Srv', label_true: 'STOPPED', handler: ->
      mongos_hosts = @hosts_with_module('ryba/mongodb/shard').join ','
      @execute
        cmd: "stop this: mongod --shardsrv #{mongos_hosts} --logappend"

    module.exports.push name: 'MongoDB Shard # Start Routing Srv', label_true: 'STOPPED', handler: ->
      mongos_hosts = @hosts_with_module('ryba/mongodb/shard').join ','
      @execute
        cmd: "stop this: mongos --configdb #{mongos_hosts} --logappend"

    module.exports.push name: 'MongoDB Shard # Start Config Srv', label_true: 'STOPPED', handler: ->
      @execute
        cmd: 'stop this: mongod --configsvr --logappend'

## Stop Clean Logs

    module.exports.push name: 'MongoDB Shard # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      {mongodb} = @config.ryba
      @execute
        cmd: "rm #{mongodb.log_dir}/*"
        code_skipped: 1
