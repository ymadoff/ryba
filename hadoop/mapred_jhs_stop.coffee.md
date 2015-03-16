
# MapReduce JobHistoryServer Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

## Stop

Stop the MapReduce Job History Password. You can also stop the server manually
with one of the following two commands:

```
service hadoop-mapreduce-historyserver stop
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf stop historyserver"
```

    module.exports.push name: 'MapReduce JHS # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hadoop-mapreduce-historyserver'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
      , next

    # module.exports.push name: 'JobHistoryServer # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
    #   lifecycle.jhs_stop ctx, next
