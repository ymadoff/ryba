
# HBase RegionServer Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    # module.exports.push require('./index').configure

## Start

Start the RegionServer server. You can also start the server manually with one of the
following two commands:

```
service hbase-regionserver start
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver"
```

    module.exports.push name: 'HBase RegionServer # Start', label_true: 'STARTED', handler: ->
      @service
        srv_name: 'hbase-regionserver'
        action: 'start'
        if_exists: '/etc/init.d/hbase-regionserver'
