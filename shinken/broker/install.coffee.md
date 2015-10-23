
# Shinken Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/mongodb'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Broker # IPTables', handler: ->
      {broker} = @config.ryba.shinken
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: broker.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker" }
        ]
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push name: 'Shinken Broker # Packages', handler: ->
      @service name: 'shinken-broker'

## Additional Modules

    module.exports.push name: 'Shinken Broker # Modules', handler: ->
      {shinken, shinken:{broker}} = @config.ryba
      return unless Object.getOwnPropertyNames(broker.modules).length > 0
      @execute
        cmd: "su -l #{shinken.user.name} 'shinken --init'"
        not_if_exists: "#{shinken.user.home}/.shinken.ini"
      for name, mod of broker.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            not_if_exec: "su -l #{shinken.user.name} 'shinken inventory | grep #{name}'"
          @extract
            source: "#{mod.archive}.zip"
            not_if_exec: "su -l #{shinken.user.name} 'shinken inventory | grep #{name}'"
          @execute
            cmd: "shinken install --local #{mod.archive}"
            not_if_exec: "su -l #{shinken.user.name} 'shinken inventory | grep #{name}'"
        else throw Error "Missing parameter: archive for broker.modules.#{name}"
      
## Dependencies

    path = require 'path'
