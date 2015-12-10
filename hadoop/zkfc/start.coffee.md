
# Hadoop ZKFC Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, to ensure that the leadership is assigned to the desired active
NameNode, the ZKFC daemons on the standy NameNodes wait for the one on the
active NameNode to start first.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push 'ryba/xasecure/policymgr_wait'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push 'ryba/hadoop/hdfs_jn/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    # module.exports.push require('./index').configure

    module.exports.push
      header: 'HDFS ZKFC # Wait Active NN'
      label_true: 'READY'
      timeout: -1
      if: [
        -> @contexts('ryba/hadoop/hdfs_nn').length > 1
        -> @config.ryba.active_nn_host isnt @config.host
      ]
      handler: ->
        {hdfs, active_nn_host} = @config.ryba
        active_shortname = @contexts(hosts: active_nn_host)[0].config.shortname
        @wait_execute
          cmd: mkcmd.hdfs @, "hdfs --config #{hdfs.nn.conf_dir} haadmin -getServiceState #{active_shortname}"
          code_skipped: 255

## Start

Start the ZKFC daemon. Important, ZKFC should start first on the active
NameNode. You can also start the server manually with the following two
commands:

```
service hadoop-hdfs-zkfc start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start zkfc"
```

    module.exports.push header: 'HDFS ZKFC # Start', label_true: 'STARTED', handler: ->
      return next() unless @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      @service_start
        name: 'hadoop-hdfs-zkfc'

## Wait Failover

Ensure a given NameNode is always active and force the failover otherwise.

In order to work properly, the ZKFC daemon must be running and the command must
be executed on the same server as ZKFC.

This middleware duplicates the one present in 'ryba/hadoop/hdfs_dn/wait' and
is only called if a DataNode isn't installed on this server because this command
only run on a NameNode with fencing installed and in normal mode.

TODO sep 2015: maybe should we simply move this to ZKFC?

    module.exports.push header: 'HDFS ZKFC # Start Failover', label_true: 'READY', handler: ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      return next() unless nn_ctxs.length > 1
      {hdfs, active_nn_host, standby_nn_host} = @config.ryba # HDFS NN and ZKFC are always on the same host
      active_nn_ctx = nn_ctxs.filter( (ctx) -> ctx.config.host is active_nn_host)[0]
      standby_nn_ctx = nn_ctxs.filter( (ctx) -> ctx.config.host isnt active_nn_host)[0]
      # {active_nn_host, standby_nn_host} = @config.ryba
      # active_nn_host = active_nn_host.split('.')[0]
      # standby_nn_host = standby_nn_host.split('.')[0]
      # This command seems to crash the standby namenode when it is made active and
      # when the active_nn is restarting and still in safemode
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs --config #{hdfs.nn.conf_dir} haadmin -getServiceState #{active_nn_ctx.config.shortcut} | grep standby;
        then hdfs --config #{hdfs.nn.conf_dir} haadmin -failover #{standby_nn_ctx.config.shortcut} #{active_nn_ctx.config.shortcut};
        else exit 2; fi
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'
