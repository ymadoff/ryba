
# HBase Start

Start the HBase Master server. You can also start the server manually with one
of the following two commands:

```
service hbase-master start
su -l hbase -c "/usr/hdp/current/hbase-master/bin/hbase-daemon.sh --config /etc/hbase-master/conf start master"
```

    module.exports = header: 'HBase Master Start', label_true: 'STARTED', handler: ->

## Wait

Wait for Kerberos, ZooKeeper and HDFS to be started.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

## Run

Start the service.

      @service.start 'hbase-master'
