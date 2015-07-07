
# WebHCat Stop

Run the command `./bin/ryba stop -m ryba/hive/webhcat` to stop the WebHCat
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

# Stop Server

Stop the WebHCat server. You can also stop the server manually with one of the
following two commands:

```
service hive-webhcat-server stop
su -l hive -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop"
```

    module.exports.push name: 'WebHCat # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hive-webhcat-server'
        action: 'stop'
        if_exists: '/etc/init.d/hive-webhcat-server'
      .then next


## Stop Clean Logs

    module.exports.push name: 'WebHCat # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx
      .execute
        cmd: 'rm /var/log/webhcat/webhcat-console*'
        code_skipped: 1
      .execute
        cmd: 'rm /var/log/webhcat/webhcat.log*'
        code_skipped: 1
      .then next
