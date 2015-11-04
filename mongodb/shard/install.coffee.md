
# MongoDB Shard Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  config.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MongoDB Shard # IPTables', handler: ->
      {shard} = @config.ryba.mongodb
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mongodb.config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

    module.exports.push name: 'MongoDB Shard # Users & Groups', handler: ->
      {mongodb} = @config.ryba
      @group mongodb.group
      @user mongodb.user

## Packages

    module.exports.push name: 'MongoDB Shard # Packages', timeout: -1, handler: ->
      @service name: 'mongodb-org-server'
      @service name: 'mongodb-org-tools'

## Layout

    module.exports.push name: 'MongoDB Shard # Layout', handler: ->
      {mongodb} = @config.ryba
      @mkdir
        destination: mongodb.shard.config.dbpath
        uid: mongodb.user.name
        gid: mongodb.group.name

## Configure

    module.exports.push name: 'MongoDB Shard # Configure', handler: ->
      {shard} = @config.ryba.mongodb
      @write
        destination: '/etc/mongodb/mongod.conf'
        write: for k, v of shard.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
