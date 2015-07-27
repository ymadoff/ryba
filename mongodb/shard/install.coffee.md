
# MongoDB Shard Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/mongodb/install'
    module.exports.push require('./index').configure

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  config.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MongoDB Shard # IPTables', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mongodb.config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Packages

    module.exports.push name: 'MongoDB Shard # Packages', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'mongodb-org-mongos'
      .then next


## Configure

    module.exports.push name: 'MongoDB # Config: ConfigSrv', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.write
        destination: '/etc/mongodb/mongoc.conf'
        write: for k, v of mongodb.conf_config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next

    module.exports.push name: 'MongoDB # Config: RoutingSrv', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.write
        destination: '/etc/mongodb/mongos.conf'
        write: for k, v of mongodb.routing_config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next

    module.exports.push name: 'MongoDB # Config: ShardSrv', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.write
        destination: '/etc/mongodb/mongod.conf'
        write: for k, v of mongodb.shard_config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next
