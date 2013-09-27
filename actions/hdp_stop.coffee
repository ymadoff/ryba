
hdp = require './hdp'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx

module.exports.push (ctx, next) ->
  {tasktraker, mapred_user} = ctx.config.hdp
  return next() unless tasktraker
  @name "HDP # Stop MapReduce TaskTracker"
  # Execute these commands on all TaskTrackers
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop tasktracker"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop tasktracker\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS


module.exports.push (ctx, next) ->
  {jobtraker, mapred_user} = ctx.config.hdp
  return next() unless jobtraker
  @name "HDP # Stop MapReduce HistoryServer"
  # Execute these commands on the JobTracker host machine
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop historyserver"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop historyserver\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {jobtraker, mapred_user} = ctx.config.hdp
  return next() unless jobtraker
  @name "HDP # Stop MapReduce JobTracker"
  # Execute these commands on the JobTracker host machine
  ctx.execute
    # su -l mapred -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop jobtracker"
    cmd: "su -l #{mapred_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop jobtracker; sleep 25\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {datanode, hdfs_user} = ctx.config.hdp
  return next() unless datanode
  @name "HDP # Stop Datanode"
  ctx.execute
    # Unsecure installation:
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode"
    # cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode\""
    # Secure installation:
    # /usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
    cmd: "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode"
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {secondary_namenode, hdfs_user} = ctx.config.hdp
  return next() unless secondary_namenode
  @name "HDP # Stop Secondary NameNode"
  ctx.execute
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop secondarynamenode"
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop secondarynamenode\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {namenode, hdfs_user} = ctx.config.hdp
  return next() unless namenode
  @name "HDP # Stop Namenode"
  ctx.execute
    # su -l hdfs -c "/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop namenode"
    cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf stop namenode\""
    code_skipped: 1
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS






