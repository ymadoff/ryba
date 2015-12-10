
# Hadoop HDFS NameNode Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, all JournalNodes shall be started.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push 'ryba/xasecure/policymgr_wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push 'ryba/hadoop/hdfs_jn/wait'
    # module.exports.push require('./index').configure

## Start Service

Start the HDFS NameNode Server. You can also start the server manually with the
following two commands:

```
service hadoop-hdfs-namenode start
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode"
```

    module.exports.push header: 'HDFS NN # Start', timeout: -1, label_true: 'STARTED', handler: ->
      @service_start
        name: 'hadoop-hdfs-namenode'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'

## Wait Safemode

Wait for HDFS safemode to exit. It isn't enough to start the NameNodes but the
majority of DataNodes also need to be running.

    module.exports.push 'ryba/hadoop/hdfs_nn/wait'


## Dependencies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'
