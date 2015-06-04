
# HBase Rest Gateway Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

    module.exports.push name: 'HBase Rest # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-rest'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-rest'
      .then next

## Stop Clean Logs

    module.exports.push name: 'HBase Rest # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {hbase, clean_logs} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: "rm #{hbase.log_dir}/*-rest-*"
        code_skipped: 1
      .execute
        cmd: "rm #{hbase.log_dir}/gc.log-*"
        code_skipped: 1
      .then next
