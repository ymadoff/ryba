
# Hadoop HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its
associated NameNodes.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop HDFS JournalNode

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-journalnode stop
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

    module.exports.push name: 'HDFS JN # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hadoop-hdfs-journalnode'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'
      , next

    module.exports.push name: 'HDFS JN # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-journalnode-*'
        code_skipped: 1
      , next
