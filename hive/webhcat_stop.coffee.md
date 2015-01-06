
# WebHCat Stop

Run the command `./bin/ryba stop -m ryba/hive/webhcat` to stop the WebHCat
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./webhcat').configure

# Stop Server

Stop the WebHCat server. You can also stop the server manually with one of the
following two commands:

```
su -l hive -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop"
service hive-webhcat-server stop
```

    module.exports.push name: 'WebHCat # Stop', label_true: 'STOPPED', callback: (ctx, next) ->
      ctx.service
        srv_name: 'hive-webhcat-server'
        action: 'stop'
        if_exists: '/etc/init.d/hive-webhcat-server'
      , next


## Stop Clean Logs

    module.exports.push name: 'WebHCat # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/webhcat/webhcat-console*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/webhcat/webhcat.log*'
        code_skipped: 1
      ], next
