
# HBase Rest Gateway Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Start

Start the Rest server. You can also start the server manually with one of the
following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start rest"
```

    module.exports.push name: 'HBase Rest # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hbase-rest'
        if_exists: '/etc/init.d/hbase-rest'
      , next

