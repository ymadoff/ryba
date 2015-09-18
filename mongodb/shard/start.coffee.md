
# MongoDB Shard Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB Shard # Start Config Srv', label_true: 'STARTED', handler: ->
      {mongodb} = @config.ryba
      @execute
        cmd: "mongod --configsvr"
      
    module.exports.push name: 'MongoDB Shard # Start Routing Srv', label_true: 'STARTED', handler: ->
      {mongodb} = @config.ryba
      mongos_hosts = @hosts_with_module('ryba/mongodb/shard').join ','
      @execute
        cmd: "mongos --configdb #{mongos_hosts}"
      
    module.exports.push name: 'MongoDB Shard # Start Shard Srv', label_true: 'STARTED', handler: ->
      {mongodb} = @config.ryba
      mongos_hosts = @hosts_with_module('ryba/mongodb/shard').join ','
      @execute
        cmd: "mongod --shardsrv #{mongos_hosts} --logappend"
      
## Dependencies

    path = require 'path'
