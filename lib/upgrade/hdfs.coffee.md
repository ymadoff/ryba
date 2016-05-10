
# Upgrade from HDP 2.3 to 2.4

## Procedure in pseudo-code

```
# on all nodes
./bin/ryba -c ./conf/env/offline.coffee install -m 'masson/**' -f
# on nn1 or nn2
kinit hdfs
hdfs dfsadmin -rollingUpgrade prepare
# wait until
hdfs dfsadmin -rollingUpgrade query | grep 'Proceed with rolling upgrade'
# on all zookeeper nodes, sequencially
hdp-select set zookeeper-server 2.3.4.0-3485
service zookeeper-server restart
# on all journal nodes, sequencially
hdp-select set hadoop-hdfs-journalnode 2.3.4.0-3485
service hadoop-hdfs-journalnode restart
# on all zkfc nodes, sequencially
hdp-select set hadoop-hdfs-namenode 2.3.4.0-3485
service hadoop-hdfs-zkfc restart
# on nn2
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode -rollingUpgrade started"
hdfs haadmin -failover master1 master2
# on nn1
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode -rollingUpgrade started"
# on each datanode
hdfs dfsadmin -shutdownDatanode `hostname`:50020 upgrade
while hdfs dfsadmin -D ipc.client.connect.max.retries=1 -getDatanodeInfo `hostname`:50020; do sleep 1; done
hdp-select set hadoop-hdfs-datanode 2.3.4.0-3485
HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
# somewhere
hdfs dfsadmin -rollingUpgrade finalize
```

## Source code

Follow official instruction from [Hortonworks HDP 2.2 Manual Upgrade][upgrade]
    
  
    exports = module.exports = []

## Steps

    exports.push
      header: 'Prepare Rolling Upgrade'
      if: -> @config.ryba.active_nn_host is @config.host
      handler: ->
        @execute
          cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade query | grep "Proceed with rolling upgrade"'
          code_skipped: 1
        @call 
          unless: -> @status -1
          handler: =>
            @register 'kexecute', require '../kexecute'
            # @kexecute
            #   krb5_user: @config.ryba.hdfs.krb5_user
            #   cmd: "hdfs dfsadmin -rollingUpgrade prepare"
            @execute
              cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade prepare'
            @wait_execute
              cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade query | grep "Proceed with rolling upgrade"'

    exports.push
      header: 'Upgrade Zookeeper'
      if: -> @has_module 'ryba/zookeeper/server'
      handler: ->
        @execute
          cmd: """
          hdp-select set zookeeper-server 2.4.0.0-169
          service zookeeper-server restart
          """
          trap: true
        @wait_connect
          host: @config.host
          port: @config.ryba.zookeeper?.port

    exports.push
      header: 'Upgrade JournalNode'
      if: -> @has_module 'ryba/hadoop/hdfs_jn'
      handler: ->
        @execute
          cmd: """
          hdp-select set hadoop-hdfs-journalnode 2.4.0.0-169
          service hadoop-hdfs-journalnode restart
          """
          trap: true
        @wait_connect
          host: @config.host
          port: @config.ryba.hdfs.site['dfs.journalnode.rpc-address']?.split(':')[1]
        @call (_, callback) ->
          setTimeout callback, 30000

    exports.push
      header: 'Upgrade ZKFC'
      if: -> @has_module 'ryba/hadoop/hdfs_zkfc'
      handler: ->
        @execute
          cmd: """
          hdp-select set hadoop-hdfs-zkfc 2.4.0.0-169
          service hadoop-hdfs-zkfc restart
          """
          trap: true

    exports.push
      header: 'Upgrade standby NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host isnt @config.host
      handler: ->
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
        for nn_ctx in nn_ctxs
          if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
          then active = nn_ctx.config.shortname
          else standby = nn_ctx.config.shortname
        @execute
          cmd: mkcmd.hdfs @, """
          service hadoop-hdfs-namenode stop
          hdp-select set hadoop-hdfs-namenode 2.4.0.0-169
          su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.nn.conf_dir}  --script hdfs start namenode -rollingUpgrade started"
          hdfs --config #{@config.ryba.hdfs.nn.conf_dir} haadmin -ns #{@config.ryba.nameservice} -failover #{active} #{standby}
          """
          trap: true

    exports.push
      header: 'Upgrade active NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host is @config.host
      handler: ->
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
        for nn_ctx in nn_ctxs
          if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
          then active = nn_ctx.config.shortname
          else standby = nn_ctx.config.shortname
        @execute
          cmd: mkcmd.hdfs @, """
          service hadoop-hdfs-namenode stop
          hdp-select set hadoop-hdfs-namenode 2.4.0.0-169
          su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.nn.conf_dir} --script hdfs start namenode -rollingUpgrade started"
          hdfs --config #{@config.ryba.hdfs.nn.conf_dir} haadmin -ns #{@config.ryba.nameservice} -failover #{standby} #{active}
          """
          trap: true

    exports.push
      header: 'Upgrade DataNode'
      if: -> @has_module 'ryba/hadoop/hdfs_dn'
      handler: ->
        @execute
          cmd: mkcmd.hdfs @, """
          hdfs dfsadmin -shutdownDatanode `hostname`:50020 upgrade
          while hdfs dfsadmin -D ipc.client.connect.max.retries=1 -getDatanodeInfo `hostname`:50020; do sleep 1; done
          hdp-select set hadoop-hdfs-datanode 2.4.0.0-169
          HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.dn.conf_dir} --script hdfs start datanode
          """
          trap: true

    exports.push
      header: 'Finalize'
      if: -> @config.ryba.active_nn_host is @config.host
      handler: ->
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
        @call ->
          for nn_ctx in nn_ctxs
            @wait_execute
              cmd: mkcmd.hdfs @, "hdfs dfsadmin -safemode get | grep OFF | grep #{nn_ctx.config.host}"
              interval: 5000
        @execute
          cmd: mkcmd.hdfs @, "hdfs dfsadmin -rollingUpgrade finalize"
          
    exports.push
      header: 'Configure ZKFC'
      if: -> @has_module 'ryba/hadoop/zkfc'
      handler: ->
        @call 'ryba/hadoop/zkfc/install'
        @call 'ryba/hadoop/zkfc/stop'
        @call 'ryba/hadoop/zkfc/start'
    
    exports.push
      header: 'Configure DataNode'
      if: -> @has_module 'ryba/hadoop/hdfs_dn'
      handler: ->
        @call 'ryba/hadoop/hdfs_dn/install'
        @call 'ryba/hadoop/hdfs_dn/stop'
        @call 'ryba/hadoop/hdfs_dn/start'   
        @call (_, callback) ->
          setTimeout callback, 45000  
           
    exports.push
      header: 'Configure JournalNode'
      if: -> @has_module 'ryba/hadoop/hdfs_jn'
      handler: ->
        @call 'ryba/hadoop/hdfs_jn/install'
        @call 'ryba/hadoop/hdfs_jn/stop'
        @call 'ryba/hadoop/hdfs_jn/start'
        @call (_, callback) ->
          setTimeout callback, 30000
        

    exports.push
      header: 'Configure standby NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host isnt @config.host
      handler: ->
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
        for nn_ctx in nn_ctxs
          if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
          then active = nn_ctx.config.shortname
          else standby = nn_ctx.config.shortname
        #make sur master1 is active
        @execute
          cmd: mkcmd.hdfs @, """
          hdfs --config #{@config.ryba.hdfs.nn.conf_dir}  haadmin -ns #{@config.ryba.nameservice} -failover #{standby} #{active}
          """
          trap: true
        @call 'ryba/hadoop/hdfs_nn/install'
        @call 'ryba/hadoop/hdfs_nn/stop'
        @call 'ryba/hadoop/hdfs_nn/start'
        

    exports.push
      header: 'Upgrade active NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host is @config.host
      handler: ->
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
        for nn_ctx in nn_ctxs
          if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
          then active = nn_ctx.config.shortname
          else standby = nn_ctx.config.shortname
        @call 'ryba/hadoop/hdfs_nn/wait'
        @execute
          cmd: mkcmd.hdfs @, """
          hdfs --config #{@config.ryba.hdfs.nn.conf_dir}  haadmin -ns #{@config.ryba.nameservice} -failover #{active} #{standby}
          """
        @call 'ryba/hadoop/hdfs_nn/install'
        @call 'ryba/hadoop/hdfs_nn/stop'
        @call 'ryba/hadoop/hdfs_nn/start'
          

## Dependencies

    util = require 'util'
    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    run = require 'masson/lib/run'
    mkcmd = require '../mkcmd'
    # parse_jdbc = require '../parse_jdbc'
