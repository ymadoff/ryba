
# Hadoop ZKFC Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the ZKFC deamon. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-zkfc stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop zkfc"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-zkfc.pid".

    module.exports.push name: 'ZKFC # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hadoop-hdfs-zkfc'
        if_exists: '/etc/init.d/hadoop-hdfs-zkfc'

    module.exports.push name: 'ZKFC # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-zkfc-*'
        code_skipped: 1
