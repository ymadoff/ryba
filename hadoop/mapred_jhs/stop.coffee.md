
# MapReduce JobHistoryServer Stop

Stop the MapReduce Job History Password. You can also stop the server manually
with one of the following two commands:

```
service hadoop-mapreduce-historyserver stop
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf stop historyserver"
```

The file storing the PID is "/var/run/hadoop-mapreduce/mapred-mapred-historyserver.pid".

    module.exports = header: 'MapReduce JHS Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'hadoop-mapreduce-historyserver'
