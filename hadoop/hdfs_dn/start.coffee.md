
# Hadoop HDFS DataNode Start

Start the DataNode service. It is recommended to start a DataNode after its associated
NameNodes. The DataNode doesn't wait for any NameNode to be started. Inside a
federated cluster, the DataNode may be dependant of multiple NameNode clusters
and some may be inactive.

You can also start the server manually with the following two commands:

```
service hadoop-hdfs-datanode start
HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
```

    module.exports = header: 'HDFS DN Start', label_true: 'STARTED', handler: ->
      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @service.start name: 'hadoop-hdfs-datanode'
