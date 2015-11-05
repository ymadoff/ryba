
# Hadoop HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its
associated the NameNodes.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Service

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-datanode stop
/usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

    module.exports.push header: 'HDFS DN # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hadoop-hdfs-datanode'
        if_exists: '/etc/init.d/hadoop-hdfs-datanode'

## Stop Clean Logs

    module.exports.push header: 'HDFS DN # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-datanode-*'
        code_skipped: 1
