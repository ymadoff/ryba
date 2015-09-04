
# MapReduce JobHistoryServer Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the MapReduce Job History Password. You can also stop the server manually
with one of the following two commands:

```
service hadoop-mapreduce-historyserver stop
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf stop historyserver"
```

    module.exports.push name: 'MapReduce JHS # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hadoop-mapreduce-historyserver'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
