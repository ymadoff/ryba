
# Hive HCatalog Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push require('./index').configure

## Start Wait Database

    module.exports.push name: 'Hive HCatalog # Start Wait DB', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive.site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, next

## Start Hive HCatalog

Start the Hive HCatalog server. You can also start the server manually with the
following two commands:

```
service hive-hcatalog-server start
su -l hive -c 'nohup hive --service metastore >/var/log/hive-hcatalog/hcat.out 2>/var/log/hive-hcatalog/hcat.err & echo $! >/var/lib/hive-hcatalog/hcat.pid'
```

    module.exports.push name: 'Hive HCatalog # Start HCatalog', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hive-hcatalog-server'
        if_exists: '/etc/init.d/hive-hcatalog-server'
      .then next
