
# MongoDB Config Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27019 |  tcp  |  configsrv.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'MongoDB ConfigSrv # IPTables', handler: ->
      {configsrv} = @config.ryba.mongodb
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: configsrv.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Config Server port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

    module.exports.push header: 'MongoDB # Users & Groups', handler: ->
      {mongodb} = @config.ryba
      @group mongodb.group
      @user mongodb.user

## Packages

    module.exports.push header: 'MongoDB ConfigSrv # Packages', timeout: -1, handler: ->
      @service name: 'mongodb-org-server'

## Layout

Config Server is just a 'classic' mongodb server, but stores configuration and 
metadata for shards.
So we create a mongod-configsrv daemon with a specific configuration file.

    module.exports.push header: 'MongoDB ConfigSrv # Layout', handler: ->
      {mongodb} = @config.ryba
      @mkdir
        destination: mongodb.configsrv.config.dbpath
        uid: mongodb.user.name
        gid: mongodb.group.name
      @copy
        source: '/etc/init.d/mongod'
        destination: '/etc/init.d/mongod-configsrv'
        unless_exists: true
      @copy
        source: '/etc/mongod.conf'
        destination: '/etc/mongod-configsrv.conf'
        unless_exists: true
      @write
        destination: '/etc/init.d/mongod-configsrv'
        write:
          match: /^CONFIGFILE=.*$/mg
          replace: 'CONFIGFILE="/etc/mongod-configsrv.conf"'
        backup: true

## Configure

    module.exports.push header: 'MongoDB ConfigSrv # Configure', handler: ->
      {configsrv} = @config.ryba.mongodb
      @write
        destination: '/etc/mongodb/mongod-configsrv.conf'
        write: for k, v of configsrv.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
