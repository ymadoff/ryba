
# Hive Server Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./server').configure

## Start Wait Database

    module.exports.push name: 'Hive & HCat Server # Start Wait DB', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive.site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, next

## Start Hive HCatalog

Start the Hive HCatalog server. You can also start the server manually with the
following command:

```
service hive-hcatalog-server start
```

    module.exports.push name: 'Hive & HCat Server # Start HCatalog', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hive-hcatalog-server'
        action: 'start'
        if_exists: '/etc/init.d/hive-hcatalog-server'
      , next

## Start Server2

Start the Hive Server2. You can also start the server manually with one of the
following two commands:

```
service hive-hcatalog-server start
su -l hive -c 'nohup /usr/lib/hive/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive/server2.pid'
```

    module.exports.push name: 'Hive & HCat Server # Start Server2', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hive-server2'
        action: 'start'
        if_exists: '/etc/init.d/hive-server2'
      , next
