
# Falcon Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop Service

    module.exports.push name: 'Falcon # Stop Service', timeout: -1, label_true: 'STOPED', callback: (ctx, next) ->
      {user} = ctx.config.ryba.falcon
      # su -l falcon -c '/usr/lib/falcon/bin/falcon-stop'
      ctx.execute
        cmd: "su -l #{user.name} -c '/usr/lib/falcon/bin/falcon-stop'"
        if_exists: '/usr/lib/falcon/bin/falcon-stop'
      , next

## Stop Clean Logs

    module.exports.push name: 'Falcon # Stop Clean Logs', timeout: -1, label_true: 'TODO', callback: (ctx, next) ->
      next null, true

