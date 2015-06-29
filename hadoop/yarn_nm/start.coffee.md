
# YARN NodeManager Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    module.exports.push require('./index').configure

## Start Server

Start the Yarn NodeManager service. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-nodemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-yarn-nodemanager/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager"
```

    module.exports.push name: 'YARN NM # Start Server', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hadoop-yarn-nodemanager'
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'
      .then next
