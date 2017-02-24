
# Hadoop ZKFC Stop

    module.exports = header: 'HDFS ZKFC Stop', label_true: 'STOPPED', handler: ->
      {clean_logs} = @config.ryba

## Stop

Stop the ZKFC deamon. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-zkfc stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop zkfc"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-zkfc.pid".

      @service.stop
        header: 'Daemon'
        label_true: 'STOPPED'
        name: 'hadoop-hdfs-zkfc'

      @system.execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: clean_logs
        cmd: 'rm /var/log/hadoop-hdfs/*/*-zkfc-*'
        code_skipped: 1
