
# Hive Server2 Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

Start the Hive Server2. You can also start the server manually with one of the
following two commands:

```
service hive-server2 start
su -l hive -c 'nohup /usr/hdp/current/hive-server2/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive-server2/hive-server2.pid'
```

    module.exports = header: 'Hive Server2 Start', timeout: -1, label_true: 'STARTED', handler: ->

Wait for Kerberos, Zookeeper, Hadoop and Hive.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hive/hcatalog/wait'

Start the service

      @service_start
        name: 'hive-server2'
