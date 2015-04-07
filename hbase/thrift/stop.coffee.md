
# HBase Thrift Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

    module.exports.push name: 'HBase Thrift # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-thrift'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-thrift'
      , next

## Stop Clean Logs

    module.exports.push name: 'HBase Thrift # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {hbase, clean_logs} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute [
        cmd: "rm #{hbase.log_dir}/*-thrift-*"
        code_skipped: 1
      ,
        cmd: "rm #{hbase.log_dir}/gc.log-*"
        code_skipped: 1
      ], next
