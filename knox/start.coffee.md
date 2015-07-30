
# Knox Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./').configure

## Start

You can also start the server manually with the following command:

```
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh start"
```

    module.exports.push name: 'Knox # Start', label_true: 'STARTED', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx.execute
        cmd: """
        if /usr/hdp/current/knox-server/bin/gateway.sh status | grep 'Gateway is running'; then exit 3; fi
        su -l #{knox.user.name} -c "/usr/hdp/current/knox-server/bin/gateway.sh start"
        """
        code_skipped: 3
      .then next
