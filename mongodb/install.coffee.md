
# MongoDB Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/yum'
    module.exports.push require('./index').configure

## Users & Groups

    module.exports.push name: 'MongoDB # Users & Groups', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx
      .group mongodb.group
      .user mongodb.user
      .then next

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  config.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MongoDB # IPTables', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mongodb.srv_config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Install

    module.exports.push name: 'MongoDB # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      # From 2.6, package are separated. But 6.4 is still monolithic
      # .service name: 'mongodb'
      .service name: 'mongodb-org-server'
      .service name: 'mongodb-org-shell'
      .service name: 'mongodb-org-tools'
      .then next

## Configure

    module.exports.push name: 'MongoDB # Configuration', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx
      .write
        destination: '/etc/mongod.conf'
        write: for k, v of mongodb.srv_config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      .mkdir
        destination: mongodb.srv_config.dbpath
        uid: mongodb.user.name
        gid: mongodb.group.name
      .then next

## Module Dependencies

    quote = require 'regexp-quote'
