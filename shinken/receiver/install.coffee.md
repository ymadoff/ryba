
# Shinken Receiver Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'

## IPTables

| Service          | Port  | Proto | Parameter       |
|------------------|-------|-------|-----------------|
| shinken-receiver | 7773  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Receiver # IPTables', handler: ->
      {receiver} = @config.ryba.shinken
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: receiver.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Receiver" }
        ]
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push name: 'Shinken Receiver # Packages', handler: ->
      {shinken} = @config.ryba
      @service
        name: 'shinken-receiver'
      @chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        not_if_exists: "#{shinken.home}/.shinken.ini"

## Additional Modules

    module.exports.push name: 'Shinken Receiver # Modules', handler: ->
      {shinken, shinken:{receiver}} = @config.ryba
      return unless Object.keys(receiver.modules).length > 0
      for name, mod of receiver.modules
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
            cmd: "su -l #{shinken.user.name} -c 'shinken install --local #{mod.archive}'"
            not_if_exec: "su -l #{shinken.user.name} 'shinken inventory | grep #{name}'"
        else throw Error "Missing parameter: archive for receiver.modules.#{name}"

## Dependencies

    path = require 'path'
