
# Hadoop YARN ResourceManager Stop

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-resourcemanager stop
su -l yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
```

    module.exports.push name: 'Yarn RM # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hadoop-yarn-resourcemanager'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'
      .then next

    module.exports.push name: 'Yarn RM # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      {clean_logs, yarn} = ctx.config.ryba
      return next() unless clean_logs
      ctx.execute
        cmd: 'rm #{yarn.log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
      .then next
