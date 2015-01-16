
# Oozie Server Stop

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Stop

Stop the Oozie service. You can also stop the server manually with the
following command:

```
su -l oozie -c "/usr/lib/oozie/bin/oozied.sh stop"
```

    module.exports.push name: 'Oozie Server # Stop', label_true: 'STOPPED', timeout: -1, handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.execute
        cmd: """
        if [ ! -f #{oozie.pid_dir}/oozie.pid ]; then exit 3; fi
        if ! kill -0 >/dev/null 2>&1 `cat #{oozie.pid_dir}/oozie.pid`; then exit 3; fi
        su -l #{oozie.user.name} -c "/usr/lib/oozie/bin/oozied.sh stop 20 -force"
        """
        code_skipped: 3
      , next

## Stop Clean Logs

    module.exports.push name: 'Oozie Server # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/oozie/*'
        code_skipped: 1
      , next
