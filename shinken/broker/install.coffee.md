
# Shinken Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'
    module.exports.push 'ryba/mongodb'
    module.exports.push require('./index').configure

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Broker # IPTables', handler: (ctx, next) ->
      {broker} = ctx.config.ryba.shinken
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: broker.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Packages

    module.exports.push name: 'Shinken Broker # Packages', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      ctx
      .service name: 'python-pymongo'
      .service name: 'shinken-broker'
      .write
        destination: '/etc/init.d/shinken-broker'
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .write
        destination: '/etc/shinken/daemons/brokerd.ini'
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

    module.exports.push name: 'Shinken Broker # Modules', handler: (ctx, next) ->
      {broker} = ctx.config.ryba.shinken
      return next() unless Object.getOwnPropertyNames(broker.modules).length > 0
      download = []
      extract = []
      exec = []
      for name, mod of broker.modules
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
        else return next Error "Missing parameter: archive for broker.modules.#{name}"
      ctx
      .download download
      .extract extract
      .execute exec
      .then next

## Module dependencies

    path = require 'path'
