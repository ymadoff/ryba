
# Hive HCatalog Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    # module.exports.push require('./index').configure

## Wait Database

    module.exports.push header: 'Hive HCatalog # Wait DB', timeout: -1, label_true: 'READY', handler: ->
      {hive} = @config.ryba
      {engine, addresses, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      @wait_connect addresses

## Start Hive HCatalog

Start the Hive HCatalog server. You can also start the server manually with the
following two commands:

```
service hive-hcatalog-server start
su -l hive -c 'nohup hive --service metastore >/var/log/hive-hcatalog/hcat.out 2>/var/log/hive-hcatalog/hcat.err & echo $! >/var/lib/hive-hcatalog/hcat.pid'
```

    module.exports.push header: 'Hive HCatalog # Start HCatalog', timeout: -1, label_true: 'STARTED', handler: ->
      @service_start name: 'hive-hcatalog-server'

# Module Dependencies

    parse_jdbc = require '../../lib/parse_jdbc'
