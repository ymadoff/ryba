
# MongoDB Shard Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the MongoDB services.

    module.exports.push name: 'MongoDB Shard # Stop Shard Srv', label_true: 'STOPPED', handler: (ctx, next) ->
      mongos_hosts = ctx.hosts_with_module('ryba/mongodb/shard').join ','
      ctx.execute
        cmd: "stop this: mongod --shardsrv #{mongos_hosts} --logappend"
      .then next

    module.exports.push name: 'MongoDB Shard # Start Routing Srv', label_true: 'STOPPED', handler: (ctx, next) ->
      mongos_hosts = ctx.hosts_with_module('ryba/mongodb/shard').join ','
      ctx.execute
        cmd: "stop this: mongos --configdb #{mongos_hosts} --logappend"
      .then next

    module.exports.push name: 'MongoDB Shard # Start Config Srv', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'stop this: mongod --configsvr --logappend'
      .then next

## Stop Clean Logs

    module.exports.push name: 'MongoDB Shard # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      {mongodb} = ctx.config.ryba
      ctx.execute
        cmd: "rm #{mongodb.log_dir}/*"
        code_skipped: 1
      .then next
