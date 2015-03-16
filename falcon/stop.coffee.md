
# Falcon Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop Service

Stop the Falcon service. You can also stop the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-stop.sh falcon"
```

    module.exports.push name: 'Falcon # Stop Service', timeout: -1, label_true: 'STOPPED', handler: (ctx, next) ->
      {user} = ctx.config.ryba.falcon
      ctx.execute
        cmd: """
          su -l #{user.name} -c '/usr/hdp/current/falcon-server/bin/service-status.sh falcon'
          if [ $? -eq 255 ]; then exit 3; fi
          su -l #{user.name} -c '/usr/hdp/current/falcon-server/bin/service-stop.sh falcon'
        """
        code_skipped: 3
        if_exists: '/usr/hdp/current/falcon-server/bin/service-stop.sh'
      , next

## Stop Clean Logs

    module.exports.push name: 'Falcon # Stop Clean Logs', timeout: -1, label_true: 'TODO', handler: (ctx, next) ->
      next null, true

