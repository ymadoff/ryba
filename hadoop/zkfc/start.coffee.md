
# Hadoop ZKFC Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, to ensure that the leadership is assigned to the desired active
NameNode, the ZKFC daemons on the standy NameNodes wait for the one on the
active NameNode to start first.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/xasecure/policymgr_wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push 'ryba/hadoop/hdfs_jn/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    # module.exports.push require('./index').configure

    module.exports.push
      name: 'ZKFC # Wait Active NN'
      label_true: 'READY'
      timeout: -1
      if: [
        -> @contexts('ryba/hadoop/hdfs_nn').length > 1
        -> @config.ryba.active_nn_host isnt @config.host
      ]
      handler: ->
        {active_nn_host} = @config.ryba
        active_shortname = @contexts(hosts: active_nn_host)[0].config.shortname
        @wait_execute
          cmd: mkcmd.hdfs @, "hdfs haadmin -getServiceState #{active_shortname}"
          code_skipped: 255

## Start

Start the ZKFC daemon. Important, ZKFC should start first on the active
NameNode. You can also start the server manually with the following two
commands:

```
service hadoop-hdfs-zkfc start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start zkfc"
```

    module.exports.push name: 'ZKFC # Start', label_true: 'STARTED', handler: ->
      return next() unless @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      @service_start
        name: 'hadoop-hdfs-zkfc'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
