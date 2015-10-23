
# MongoDB Shard Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

    module.exports.push name: 'MongoDB Shard # Start', label_true: 'STARTED', handler: ->
      {mongodb} = @config.ryba
      mongos_hosts = @hosts_with_module('ryba/mongodb/router').join ','
      @execute
        cmd: "mongod --shardsrv #{mongos_hosts} --logappend"

## Dependencies

    path = require 'path'
