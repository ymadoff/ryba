
# Shinken Reactionner Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'
    module.exports.push require('./index').configure

## IPTables

| Service             | Port  | Proto | Parameter        |
|---------------------|-------|-------|------------------|
| shinken-reactionner | 7769  |  tcp  |    config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Reactionner # IPTables', handler: (ctx, next) ->
      {reactionner} = ctx.config.ryba.shinken
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: reactionner.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Packages

    module.exports.push name: 'Shinken Reactionner # Packages', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      ctx.service name: 'shinken-reactionner'
      .chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      .execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        not_if_exists: "#{shinken.home}/.shinken.ini"
      .then next

## Additional Modules

    module.exports.push name: 'Shinken Reactionner # Modules', handler: (ctx, next) ->
      {reactionner} = ctx.config.ryba.shinken
      return next() unless Object.getOwnPropertyNames(reactionner.modules).length > 0
      download = []
      extract = []
      exec = []
      for name, mod of reactionner.modules
        if mod.archive?
          download.push
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          extract.push
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          exec.push
            cmd: "shinken install --local #{mod.archive}"
            not_if_exec: "shinken inventory | grep #{name}"
        else return next Error "Missing parameter: archive for reactionner.modules.#{name}"
      ctx
      .download download
      .extract extract
      .execute exec
      .then next

## Dependencies

    path = require 'path'
