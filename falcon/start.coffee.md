
# Falcon Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Start Service

    module.exports.push name: 'Falcon # Start Service', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      {user} = ctx.config.ryba.falcon
      # su -l falcon -c '/usr/lib/falcon/bin/falcon-start'
      ctx.execute
        cmd: """
        su -l #{user.name} -c '/usr/lib/falcon/bin/falcon-status'
        if [ $? -eq 254 ]; then exit 3; fi
        su -l #{user.name} -c '/usr/lib/falcon/bin/falcon-start'
        """
        code_skipped: 3
      , next
