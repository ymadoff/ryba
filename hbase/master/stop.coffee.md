
# HBase Master Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-master stop
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
```

    module.exports.push name: 'HBase Master # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-master'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-master'
      .then (err, stoped) ->
        return next null, stoped unless err
        ctx
        .execute
          cmd: 'service hbase-master force-stop'
        .then next

## Stop Clean Logs

    module.exports.push name: 'HBase Master # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {hbase, clean_logs} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute [
        cmd: "rm #{hbase.log_dir}/*-master-*"
        code_skipped: 1
      ,
        cmd: "rm #{hbase.log_dir}/gc.log-*"
        code_skipped: 1
      ], next
