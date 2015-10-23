
# MongoDB Router Install

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

    module.exports.push name: 'MongoDB Router # IPTables', handler: ->
      {router} = @config.ryba.mongodb
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: router.config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

    module.exports.push name: 'MongoDB # Users & Groups', handler: ->
      {mongodb} = @config.ryba
      @group mongodb.group
      @user mongodb.user

## Packages

    module.exports.push name: 'MongoDB Router # Packages', timeout: -1, handler: ->
      @service name: 'mongodb-org-mongos'

## Configure

    module.exports.push name: 'MongoDB Router # Configure', handler: ->
      {router} = @config.ryba.mongodb
      @write
        destination: '/etc/mongodb/mongos.conf'
        write: for k, v of router.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
