
# Zookeeper Server Start

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push require('./index').configure

## Start

Start the ZooKeeper server. You can also start the server manually with the
following two commands:

```
service zookeeper-server start
su - zookeeper -c "export ZOOCFGDIR=/usr/hdp/current/zookeeper-server/conf; export ZOOCFG=zoo.cfg; source /usr/hdp/current/zookeeper-server/conf/zookeeper-env.sh; /usr/hdp/current/zookeeper-server/bin/zkServer.sh start"
```

    module.exports.push name: 'ZooKeeper Server # Start Server', label_true: 'STARTED', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      ctx
      .service_start
        name: 'zookeeper-server'
        if_exists: '/etc/init.d/zookeeper-server'
      .then next
