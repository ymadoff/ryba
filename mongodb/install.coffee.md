
# MongoDB Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/yum'

## Users & Groups

    module.exports.push name: 'MongoDB # Users & Groups', handler: ->
      {mongodb} = @config.ryba
      @group mongodb.group
      @user mongodb.user


## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  config.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MongoDB # IPTables', handler: ->
      {mongodb} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mongodb.srv_config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: @config.iptables.action is 'start'

## Install

    module.exports.push name: 'MongoDB # Install', timeout: -1, handler: ->
      # From 2.6, package are separated. But 6.4 is still monolithic
      # .service name: 'mongodb'
      @service name: 'mongodb-org-server'
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'

## Configure

    module.exports.push name: 'MongoDB # Configure', handler: ->
      {mongodb} = @config.ryba
      @write
        destination: '/etc/mongod.conf'
        write: for k, v of mongodb.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @mkdir
        destination: mongodb.config.dbpath
        uid: mongodb.user.name
        gid: mongodb.group.name

## Dependencies

    quote = require 'regexp-quote'
