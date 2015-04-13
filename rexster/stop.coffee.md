
# Rexster Stop

Run the command `./bin/ryba stop -m ryba/titan/rexster` to stop the Rexster
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Stop

Stop the Rexster server. You can also stop the server manually with the
following command:

```
ps aux | grep "rexster"

kill ...
```

    module.exports.push name: 'Rexster # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      {titan, rexster} = ctx.config.ryba
      ctx.execute
        cmd: """
        p = `ps aux | grep "com.tinkerpop.rexster.Application"`
        if [ -z "$p" ]; then exit 3; fi
        #{path.join titan.home, 'bin', 'rexster.sh'} --stop --wait -rp #{rexster.config['shutdown-port']} | grep 'Rexster Server shutdown complete'
        """
        code_skipped: 3
      , next

## Module Dependencies

    path = require 'path'