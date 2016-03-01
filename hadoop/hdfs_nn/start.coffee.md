
# Hadoop HDFS NameNode Start

Start the NameNode service as well as its ZKFC daemon. In HA mode, all
JournalNodes shall be started.

You can also start the server manually with the following two commands:

```
service hadoop-hdfs-namenode start
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode"
```

    module.exports = header: 'HDFS NN Start', timeout: -1, label_true: 'STARTED', handler: ->
      @service_start
        name: 'hadoop-hdfs-namenode'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'
