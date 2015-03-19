
# Hadoop ZKFC Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, to ensure that the leadership is assigned to the desired active
NameNode, the ZKFC daemons on the standy NameNodes wait for the one on the
active NameNode to start first.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/xasecure/policymgr_wait'
    module.exports.push 'ryba/zookeeper/server_wait'
    module.exports.push 'ryba/hadoop/hdfs_jn_wait'
    # module.exports.push 'ryba/hadoop/hdfs_nn_wait'
    module.exports.push require('./index').configure

## Start

Start the HDFS ZKFC daemon. Important, ZKFC should start first on the active
NameNode. You can also start the server manually with the following two
commands:

```
service hadoop-hdfs-zkfc start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start zkfc"
```

    module.exports.push name: 'HDFS ZKFC # Start', label_true: 'STARTED', handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      # {active_nn_host} = ctx.config.ryba
      # do_wait = ->
      #   ctx.waitForExecution
      #     cmd: mkcmd.hdfs ctx, "hdfs haadmin -getServiceState #{ctx.config.shortname}"
      #     code_skipped: 255
      #   , (err, stdout) ->
      #     return next err if err
      #     do_start()
      # do_start = ->
      #   ctx.service
      #     srv_name: 'hadoop-hdfs-zkfc'
      #     action: 'start'
      #     if_exists: '/etc/init.d/hadoop-hdfs-zkfc'
      #   , next
      # if active_nn_host is ctx.config.host then do_start() else do_wait()
      ctx.service
        srv_name: 'hadoop-hdfs-zkfc'
        action: 'start'
        if_exists: '/etc/init.d/hadoop-hdfs-zkfc'
      , next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
