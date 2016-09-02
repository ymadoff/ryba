
# MapReduce JobHistoryServer (JHS) Start

Start the MapReduce Job History Server. You can also start the server manually with the
following command:

```
service hadoop-mapreduce-historyserver start
su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-mapreduce-historyserver/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
```

It is recommended but not required to start the JHS server before the Resource
Manager. If started after after, the ResourceManager will print a message in the
log file complaining it cant reach the JSH server (default port is "10020").

    module.exports = header: 'MapReduce JHS # Start', timeout: -1, label_true: 'STARTED', handler: ->

Wait for the DataNode and NameNode to be started to fetch all history.

      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

Start the service.

      @service.start
        name: 'hadoop-mapreduce-historyserver'
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
