
# Shinken Reactionner Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'

## IPTables

| Service             | Port  | Proto | Parameter        |
|---------------------|-------|-------|------------------|
| shinken-reactionner | 7769  |  tcp  |    config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Reactionner # IPTables', handler: ->
      {reactionner} = @config.ryba.shinken
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: reactionner.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner" }
        ]
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push name: 'Shinken Reactionner # Packages', handler: ->
      {shinken} = @config.ryba
      @service
        name: 'shinken-reactionner'
      @chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        not_if_exists: "#{shinken.home}/.shinken.ini"

## Additional Modules

    module.exports.push name: 'Shinken Reactionner # Modules', handler: ->
      {reactionner} = @config.ryba.shinken
      return unless Object.getOwnPropertyNames(reactionner.modules).length > 0
      for name, mod of reactionner.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          @exec
            cmd: "shinken install --local #{mod.archive}"
            not_if_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for reactionner.modules.#{name}"

## Dependencies

    path = require 'path'
