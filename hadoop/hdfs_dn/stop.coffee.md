
# Hadoop HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its
associated the NameNodes.

You can also stop the server manually with one of the following two commands:

```
service hadoop-hdfs-datanode stop
/usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

    module.exports = header: 'HDFS DN Stop', label_true: 'STOPPED', handler: ->

      @service.stop
        header: 'HDFS DN Stop'
        label_true: 'STOPPED'
        name: 'hadoop-hdfs-datanode'
        if_exists: '/etc/init.d/hadoop-hdfs-datanode'

## Stop Clean Logs

      @execute
        header: 'HDFS DN Clean Logs'
        label_true: 'CLEANED'
        if: @config.ryba.clean_logs
        cmd: 'rm /var/log/hadoop-hdfs/*/*-datanode-*'
        code_skipped: 1
