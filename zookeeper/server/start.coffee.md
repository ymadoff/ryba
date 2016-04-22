
# Zookeeper Server Start

Start the ZooKeeper server. You can also start the server manually with the
following two commands:

```
service zookeeper-server start
su - zookeeper -c "export ZOOCFGDIR=/usr/hdp/current/zookeeper-server/conf; export ZOOCFG=zoo.cfg; source /usr/hdp/current/zookeeper-server/conf/zookeeper-env.sh; /usr/hdp/current/zookeeper-server/bin/zkServer.sh start"
```

    module.exports = header: 'ZooKeeper Server # Start', label_true: 'STARTED', handler: ->
    
Wait for Kerberos to be started.

      @call once: true, 'masson/core/krb5_client/wait'

Start the service.

      @service_start name: 'zookeeper-server'
