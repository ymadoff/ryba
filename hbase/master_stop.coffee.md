
# HBase Master Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./master').configure

# Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-master stop
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
```

    module.exports.push name: 'HBase RegionServer # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-master'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-master'
      , next

## Stop Clean Logs

    module.exports.push name: 'HBase Master # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hbase/*-master-*'
        code_skipped: 1
      , next
