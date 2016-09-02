
# Hadoop HDFS SecondaryNameNode Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-secondarynamenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop secondarynamenode"
```

    module.exports.push header: 'HDFS SNN # Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'hadoop-hdfs-secondarynamenode'
        if_exists: '/etc/init.d/hadoop-hdfs-secondarynamenode'

## Stop Clean Logs

Remove the "\*-namenode-\*" log files if the property "ryba.clean_logs" is
activated.

    module.exports.push header: 'HDFS SNN # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      @execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-secondarynamenode-*'
        code_skipped: 1
        if: @config.ryba.clean_logs
