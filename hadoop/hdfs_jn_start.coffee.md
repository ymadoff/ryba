
# Hadoop HDFS JournalNode Start

Start the JournalNode service. It is recommended to start a JournalNode before the
NameNodes. The "ryba/hadoop/hdfs_nn" module will wait for all the JournalNodes
to be started on the active NameNode before it check if it must be formated.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server_wait'

## Start HDFS JournalNode

Start the HDFS JournalNode server. You can also start the server manually with
the following two commands:

```
service hadoop-hdfs-journalnode start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start journalnode"
```

    module.exports.push name: 'HDFS JN # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hadoop-hdfs-journalnode'
        action: 'start'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'
      , next
