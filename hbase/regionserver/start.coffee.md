
# HBase RegionServer Start

Start the RegionServer server. You can also start the server manually with one of the
following two commands:

```
service hbase-regionserver start
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase-regionserver/conf start regionserver"
```

    module.exports = header: 'HBase RegionServer Start', label_true: 'STARTED', handler: ->

Wait for Kerberos, ZooKeeper, HDFS and HBase Master to be started.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hbase/master/wait'

Start the service.

      @service.start
        name: 'hbase-regionserver'
        if_exists: '/etc/init.d/hbase-regionserver'
