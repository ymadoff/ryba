# HBase Thrift Server Start

Start the Thrift server. You can also start the server manually with one of the
following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf start thrift"
```

    module.exports =  header: 'HBase Thrift Start', label_true: 'STARTED', handler: ->

Wait for Kerberos, ZooKeeper, HDFS and Hbase Master to be started.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hbase/master/wait'

Start the service.

      @service.start
        name: 'hbase-thrift'
