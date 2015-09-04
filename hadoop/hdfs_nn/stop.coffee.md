
# Hadoop HDFS NameNode Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop namenode"
```

    module.exports.push name: 'HDFS NN # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hadoop-hdfs-namenode'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'

## Stop Clean Logs

Remove the "\*-namenode-\*" log files if the property "ryba.clean_logs" is
activated.

    module.exports.push name: 'HDFS NN # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      @execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-namenode-*'
        code_skipped: 1
        if: @config.ryba.clean_logs
