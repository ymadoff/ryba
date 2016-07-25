
# Hive HCatalog Start


## Start Hive HCatalog

Start the Hive HCatalog server. You can also start the server manually with the
following two commands:

```
service hive-hcatalog-server start
su -l hive -c 'nohup hive --service metastore >/var/log/hive-hcatalog/hcat.out 2>/var/log/hive-hcatalog/hcat.err & echo $! >/var/lib/hive-hcatalog/hcat.pid'
```

    module.exports =  header: 'Hive HCatalog Start', timeout: -1, label_true: 'STARTED', handler: ->
      {hive} = @config.ryba
      {engine, addresses, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      
## Wait
      
      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/zookeeper/server/wait'

## Wait Database

The Hive HCatalog require the database server to be started. The Hive Server2
require the HFDS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

      @call header: 'Wait DB', timeout: -1, label_true: 'READY', handler: ->
        @wait_connect addresses

      @service_start
        header: 'Start service'
        label_true: 'STARTED'
        timeout: -1
        name: 'hive-hcatalog-server'

# Module Dependencies

    parse_jdbc = require '../../lib/parse_jdbc'
