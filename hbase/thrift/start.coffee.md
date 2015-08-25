# HBase Thrift Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Start

Start the Thrift server. You can also start the server manually with one of the
following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf start thrift"
```

    module.exports.push name: 'HBase Thrift # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hbase-thrift'
        action: 'start'
        if_exists: '/etc/init.d/hbase-thrift'
      , next