
# Hadoop HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its
associated NameNodes.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop HDFS JournalNode

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-journalnode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-journalnode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop journalnode"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-journalnode.pid".

    module.exports.push header: 'HDFS JN # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hadoop-hdfs-journalnode'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'

    module.exports.push header: 'HDFS JN # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      @execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-journalnode-*'
        code_skipped: 1
        if: @config.ryba.clean_logs
