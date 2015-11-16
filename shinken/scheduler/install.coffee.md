
# Shinken Scheduler Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
| shinken-scheduler | 7768  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Shinken Scheduler # IPTables', handler: ->
      {scheduler} = @config.ryba.shinken
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: scheduler.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Scheduler" }
        ]
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push header: 'Shinken Scheduler # Packages', handler: ->
      {shinken} = @config.ryba
      @service name: 'shinken-scheduler'
      @chown
        destination: shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        unless_exists: "#{shinken.home}/.shinken.ini"

## Additional Modules

    module.exports.push header: 'Shinken Scheduler # Modules', handler: ->
      {shinken, shinken:{scheduler}} = @config.ryba
      return unless Object.keys(scheduler.modules).length > 0
      for name, mod of scheduler.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @execute
            cmd: "shinken install --local #{mod.archive}"
            unless_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for scheduler.modules.#{name}"

## Dependencies

    path = require 'path'
