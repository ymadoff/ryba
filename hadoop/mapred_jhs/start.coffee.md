
# MapReduce JobHistoryServer (JHS) Start

It is recommended but not required to start the JHS server before the Resource
Manager. If started after after, the ResourceManager will print a message in the
log file complaining it cant reach the JSH server (default port is "10020").

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Start

Start the MapReduce Job History Server. You can also start the server manually with the
following command:

```
service hadoop-mapreduce-historyserver start
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-mapreduce-historyserver/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
```

    module.exports.push name: 'MapReduce JHS # Start', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hadoop-mapreduce-historyserver'
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
      .then next
