
# Hadoop HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its
associated NameNodes.

You can also stop the server manually with one of the following two commands:

```
service hadoop-hdfs-journalnode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-journalnode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop journalnode"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-journalnode.pid".

    module.exports = header: 'HDFS JN Stop', label_true: 'STOPPED', handler: ->

      @service_stop
        header: 'HDFS JN # Stop'
        label_true: 'STOPPED'
        name: 'hadoop-hdfs-journalnode'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'    

Clean up the log files related to the JournalNode

      @execute
        header: 'HDFS JN Clean Logs'
        label_true: 'CLEANED'
        if: @config.ryba.clean_logs
        cmd: 'rm /var/log/hadoop-hdfs/*/*-journalnode-*'
        code_skipped: 1
