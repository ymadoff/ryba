
# MongoDB Shard Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'MongoDB Shard # Start Config Srv', label_true: 'STARTED', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.execute
        cmd: "mongod --configsvr"
      .then next

    module.exports.push name: 'MongoDB Shard # Start Routing Srv', label_true: 'STARTED', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      mongos_hosts = ctx.hosts_with_module('ryba/mongodb/shard').join ','
      ctx.execute
        cmd: "mongos --configdb #{mongos_hosts}"
      .then next

    module.exports.push name: 'MongoDB Shard # Start Shard Srv', label_true: 'STARTED', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      mongos_hosts = ctx.hosts_with_module('ryba/mongodb/shard').join ','
      ctx.execute
        cmd: "mongod --shardsrv #{mongos_hosts} --logappend"
      .then next

## Module Dependencies

    path = require 'path'
