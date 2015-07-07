
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
      daemon = 'reactionner'
      ctx
      .service
        name: "shinken-#{daemon}"
      .write
        destination: "/etc/init.d/shinken-#{daemon}"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .write
        destination: "/etc/shinken/daemons/#{daemon}d.ini"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      .execute
        cmd: "shinken --init"
        not_if_exists: ".shinken.ini"
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
            not_if_exec: "shinken inventory | grep #{name}"
          extract.push
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          exec.push
            cmd: "su -l #{ctx.config.ryba.shinken.user.name} -c 'shinken install --local #{mod.archive}'"
            not_if_exec: "shinken inventory | grep #{name}"
        else return next Error "Missing parameter: archive for reactionner.modules.#{name}"
      ctx
      .download download
      .extract extract
      .execute exec
      .then next

## Module dependencies

    path = require 'path'
