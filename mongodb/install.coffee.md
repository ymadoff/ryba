
# MongoDB Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/yum'

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  config.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'MongoDB # IPTables', handler: ->
      {mongodb} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mongodb.config.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

    module.exports.push header: 'MongoDB # Users & Groups', handler: ->
      {mongodb} = @config.ryba
      @group mongodb.group
      @user mongodb.user

## Install

    module.exports.push header: 'MongoDB # Install', timeout: -1, handler: ->
      # From 2.6, package are separated. But 6.4 is still monolithic
      # .service name: 'mongodb'
      @service name: 'mongodb-org-server'
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'

## Layout

    module.exports.push header: 'MongoDB # Layout', handler: ->
      {mongodb} = @config.ryba
      @mkdir
        destination: mongodb.config.dbpath
        uid: mongodb.user.name
        gid: mongodb.group.name


## Configure

    module.exports.push header: 'MongoDB # Configure', handler: ->
      {mongodb} = @config.ryba
      @write
        destination: '/etc/mongod.conf'
        write: for k, v of mongodb.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Dependencies

    quote = require 'regexp-quote'
