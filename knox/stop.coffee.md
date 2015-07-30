
# Knox Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./').configure

## Start

You can also stop the server manually with the following command:

```
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh stop"
```

    module.exports.push name: 'Knox # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx.execute
        cmd: """
        if /usr/hdp/current/knox-server/bin/gateway.sh status | grep 'Gateway is not running'; then exit 3; fi
        su -l #{knox.user.name} -c "/usr/hdp/current/knox-server/bin/gateway.sh stop"
        """
        code_skipped: 3
      .then next
