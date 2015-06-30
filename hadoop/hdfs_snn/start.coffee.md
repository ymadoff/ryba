
# Hadoop HDFS SecondaryNameNode Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure
xports.push require('./index').configure

## Start Service

Start the HDFS NameNode Server. You can also start the server manually with the
following two commands:

```
service hadoop-hdfs-secondarynamenode start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start secondarynamenode"
```

    module.exports.push name: 'HDFS SNN # Start', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hadoop-hdfs-secondarynamenode'
        if_exists: '/etc/init.d/hadoop-hdfs-secondarynamenode'
      .then next
