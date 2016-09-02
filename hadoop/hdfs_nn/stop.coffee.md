
# Hadoop HDFS NameNode Stop


    module.exports = header: 'HDFS NN Stop', label_true: 'STOPPED', handler: ->

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop namenode"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-namenode.pid".

      @service.stop
        header: 'HDFS NN Stop'
        label_true: 'STOPPED'
        name: 'hadoop-hdfs-namenode'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'

## Stop Clean Logs

Remove the "\*-namenode-\*" log files if the property "ryba.clean_logs" is
activated.

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        cmd: 'rm /var/log/hadoop-hdfs/*-namenode-*'
        code_skipped: 1
        if: @config.ryba.clean_logs
