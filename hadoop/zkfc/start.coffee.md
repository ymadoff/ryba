
# Hadoop ZKFC Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, to ensure that the leadership is assigned to the desired active
NameNode, the ZKFC daemons on the standy NameNodes wait for the one on the
active NameNode to start first.

    module.exports = header: 'HDFS ZKFC Start', label_true: 'STARTED', handler: ->
      {hdfs, active_nn_host, standby_nn_host} = @config.ryba
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      active_shortname = nn_ctxs.filter( (nn) -> nn.config.host is active_nn_host )[0].config.shortname
      standby_shortname = nn_ctxs.filter( (nn) -> nn.config.host is standby_nn_host )[0].config.shortname

## Wait

Wait for Kerberos, ZooKeeper and HDFS to be started.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_jn/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

## Wait Active NN

      @wait.execute
        header: 'Wait Active NN'
        label_true: 'READY'
        timeout: -1
        if: [
          # nn_ctxs.length > 1
          active_nn_host isnt @config.host
        ]
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

      @service.start
        header: 'Daemon', label_true: 'STARTED'
        name: 'hadoop-hdfs-zkfc'
        # if: nn_ctxs.length > 1

## Wait Failover

Ensure a given NameNode is always active and force the failover otherwise.

In order to work properly, the ZKFC daemon must be running and the command must
be executed on the same server as ZKFC.

      # Note, probably we shall wait for the other NameNode to be started and running
      # before attempting to activate it.
      @system.execute
        header: 'Failover'
        label_true: 'READY'
        # if: nn_ctxs.length > 1
        cmd: mkcmd.hdfs @, """
        if hdfs --config #{hdfs.nn.conf_dir} haadmin -getServiceState #{active_shortname} | grep standby;
        then hdfs --config #{hdfs.nn.conf_dir} haadmin -ns #{@config.ryba.nameservice} -failover #{standby_shortname} #{active_shortname};
        else exit 2; fi
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'
