
hdp = require './hdp'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx

module.exports.push (ctx, next) ->
  {namenode, hdfs_user} = ctx.config.hdp
  return next() unless namenode
  @name "HDP # Start Namenode"
  ctx.execute
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode"
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode\""
    code_skipped: 1
  , (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {secondary_namenode, hdfs_user} = ctx.config.hdp
  return next() unless secondary_namenode
  @name "HDP # Start Secondary NameNode"
  ctx.execute
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode"
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode\""
    code_skipped: 1
  , (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {datanode, hdfs_user} = ctx.config.hdp
  return next() unless datanode
  @name "HDP # Start Datanode"
  ctx.execute
    # Unsecure installation:
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode"
    # cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode\""
    # Secure installation:
    # /usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode
    cmd: "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start datanode"
    code_skipped: 1
  , (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {jobtraker, mapred_user} = ctx.config.hdp
  return next() unless jobtraker
  @name "HDP # Start MapReduce JobTracker"
  # Execute these commands on the JobTracker host machine
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start jobtracker"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start jobtracker; sleep 25\""
    code_skipped: 1
  , (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {jobhistoryserver, mapred_user} = ctx.config.hdp
  return next() unless jobhistoryserver
  @name "HDP # Start MapReduce HistoryServer"
  # Execute these commands on the JobTracker host machine
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start historyserver"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start historyserver\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {tasktraker, mapred_user} = ctx.config.hdp
  return next() unless tasktraker
  @name "HDP # Start MapReduce TaskTracker"
  # Execute these commands on all TaskTrackers
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start tasktracker"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start tasktracker\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
