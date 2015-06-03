
# MapReduce JobHistoryServer Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Start

Start the MapReduce Job History Server. You can also start the server manually with the
following command:

```
service hadoop-mapreduce-historyserver start
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
```

    module.exports.push name: 'MapReduce JHS # Start', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hadoop-mapreduce-historyserver'
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
      .then next
