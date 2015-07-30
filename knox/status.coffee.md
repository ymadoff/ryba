
# Knox Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./').configure

## Start

You can also manually get the server status with the following command:

```
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh status"
```

    module.exports.push name: 'Knox # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx.execute
        cmd: "/usr/hdp/current/knox-server/bin/gateway.sh status"
        code: 1
        code_skipped: 0
      .then next
