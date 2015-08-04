
# HBase Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    module.exports.push require('./index').configure

## Start

Start the HBase Master server. You can also start the server manually with one
of the following two commands:

```
service hbase-master start
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase/conf start master"
```

    module.exports.push name: 'HBase Master # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hbase-master'
        if_exists: '/etc/init.d/hbase-master'
      .then next
