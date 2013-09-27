

module.exports.push (ctx) ->
  ctx.config.hdp ?= {}
  ctx.config.hdp.hdfs_user ?= 'hdfs'
  ctx.config.hdp.mapred_user ?= 'mapred'
  ctx.config.hdp.zookeeper_user ?= 'zookeeper'
  ctx.config.hdp.hbase_user ?= 'hbase'
  ctx.config.hdp.yarn_user ?= 'yarn'
  ctx.config.hdp.hive_user ?= 'hive'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.webhcat_user ?= 'hcat'

module.exports.push (ctx, next) ->
  @name "HDP # Start Namenode"
  {hdfs_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Start Secondary NameNode"
  {hdfs_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Start Datanode"
  {hdfs_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Yarn Resource Manager
---------------------------
Execute these commands on the ResourceManager host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Yarn Resource Manager"
  {yarn_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{yarn_user} -c \"/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Yarn History Server
-------------------------
Execute these commands on the JobTracker History Server host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Yarn History Server"
  {mapred_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh start historyserver --config /etc/hadoop/conf\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Yarn Node Manager
-----------------------
Execute these commands on all NodeManagers.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Yarn Node Manager"
  {yarn_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{yarn_user} -c \"/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push (ctx, next) ->
  # Execute these commands on the ZooKeeper host machine machine(s)
  @name "HDP # Start ZooKeeper"
  {zookeeper_user} = ctx.config.hdp
  ctx.execute
    cmd: "su - #{zookeeper_user} -c \"export  ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start HBase Master
------------------
Execute these commands on the HBase Master host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start HBase Master"
  {hbase_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{{hbase_user}} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master; sleep 25\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start HBase Region Server
-------------------------
Execute these commands on all RegionServers.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start HBase Region Servers"
  {hbase_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{{hbase_user}} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Hive Metastore
--------------------
Execute these commands on the Hive Metastore host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Hive Metastore"
  {hive_user, hive_log_dir} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{hive_user} -c \"env HADOOP_HOME=/usr nohup hive --service metastore > #{hive_log_dir} /hive.out 2> #{hive_log_dir} /hive.log &\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Hive Server2"
  {hive_user, hive_log_dir} = ctx.config.hdp
  ctx.execute
    cmd: "sudo su #{hive_user} -c \"nohup /usr/lib/hive/bin/hiveserver2 -hiveconf hive.metastore.uris=\" \" > #{hive_log_dir} /hiveServer2.out 2>#{hive_log_dir}/hiveServer2.log &\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Tez
---------
Execute these commands on the Tez host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Tez"
  ctx.execute
    cmd: "/usr/lib/tez/sbin/tez-daemon.sh start ampoolservice"
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start WebHCat
-------------
Execute these commands on the WebHCat host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start WebHCat"
  {webhcat_user} = ctx.config.hdp
  ctx.execute
    cmd: "su -l #{webhcat_user} -c \"/usr/lib/hcatalog/sbin/webhcat_server.sh start\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Oozie
-----------
Execute these commands on the Oozie server host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Oozie host machine"
  ctx.execute
    cmd: "su -l oozie -c \"/usr/lib/oozie/bin/oozie-start.sh\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS













