
# Hive Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Stop Server2

Stop the Hive Server2. You can also stop the server manually with one of
the following two commands:

```
service hive-server2 stop
su -l hive -c 'nohup /usr/lib/hive/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive/server2.pid'
```

    module.exports.push name: 'Hive & HCat # Stop Hive Server2', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hive-server2'
        action: 'stop'
        if_exists: '/etc/init.d/hive-server2'
      , next

## Stop Hive Metastore

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hive-hcatalog-server stop
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

    module.exports.push name: 'Hive & HCat # Stop Hive Metastore', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hive-hcatalog-server'
        action: 'stop'
        if_exists: '/etc/init.d/hive-hcatalog-server'
      , next

## Stop Clean Logs

    module.exports.push name: 'Hive & HCat # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hive-hcatalog/*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hive/*'
        code_skipped: 1
      ], next

