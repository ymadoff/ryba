
# Hadoop HDFS NameNode Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop NameNode

Stop the HDFS Namenode Server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop namenode"
```

    module.exports.push name: 'HDFS NN # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hadoop-hdfs-namenode'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'
      , next

    module.exports.push name: 'HDFS NN # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hadoop-hdfs/*/*-namenode-*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hadoop-hdfs/*/*-zkfc-*'
        code_skipped: 1
      ], next
