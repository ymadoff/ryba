
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
      daemon = 'broker'
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
      .then next

## WebUI
