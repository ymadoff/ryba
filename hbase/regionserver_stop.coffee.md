
# HBase RegionServer Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./regionserver').configure

# Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-regionserver start
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
```

    module.exports.push name: 'HBase RegionServer # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-regionserver'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-regionserver'
      , next

## Stop Clean Logs

    module.exports.push name: 'HBase RegionServer # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hbase/*-regionserver-*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hbase/gc.log-*'
        code_skipped: 1
      ], next
