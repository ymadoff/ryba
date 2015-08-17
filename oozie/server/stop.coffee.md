
# Oozie Server Stop

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the Oozie service. You can also stop the server manually with the
following command:

```
service stop oozie
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop"
```

    module.exports.push name: 'Oozie Server # Stop', label_true: 'STOPPED', timeout: -1, handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.service_stop
        name: 'oozie'
      .then next

## Stop Clean Logs

    module.exports.push name: 'Oozie Server # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/oozie/*'
        code_skipped: 1
      , next
