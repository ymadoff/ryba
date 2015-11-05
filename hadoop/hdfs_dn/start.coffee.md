
# Hadoop HDFS DataNode Start

Start the DataNode service. It is recommended to start a DataNode after its associated
NameNodes. The DataNode doesn't wait for any NameNode to be started. Inside a
federated cluster, the DataNode may be dependant of multiple NameNode clusters
and some may be inactive.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    # module.exports.push require('./index').configure

## Start HDFS DataNode

Start the HDFS DataNode server. You can also start the server manually with
the following two commands:

```
service hadoop-hdfs-datanode start
HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
```

    module.exports.push header: 'HDFS DN # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hadoop-hdfs-datanode'
        if_exists: '/etc/init.d/hadoop-hdfs-datanode'
