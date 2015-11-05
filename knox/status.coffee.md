
# Knox Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

You can also manually get the server status with the following command:

```
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh status"
```

    module.exports.push header: 'Knox # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {knox} = @config.ryba
      @execute
        cmd: "/usr/hdp/current/knox-server/bin/gateway.sh status"
        code: 1
        code_skipped: 0
