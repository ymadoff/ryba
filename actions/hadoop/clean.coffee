
module.exports = [
  (ctx, next) ->
    @name 'Hadoop YARN: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-yarn/*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Hadoop MapReduce: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-mapreduce/*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Hadoop MapReduce 0.20: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-0.20-mapreduce/*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Hadoop Datanode HTTP: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-hdfs/*-DATANODE-*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Hadoop Datanode HTTPFS: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-httpfs/*', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Hadoop Namenode: clean logs'
    ctx.ssh.exec 'rm -rf /var/log/hadoop-hdfs/*-NAMENODE-*; rm -rf /var/log/hadoop-hdfs/*-SECONDARYNAMENODE-*; rm -rf /var/log/hadoop-hdfs/hdfs-audit.log; rm -rf /var/log/hadoop-hdfs/SecurityAuth-hdfs.audit', (err, stream) ->
      return next err if err
      stream.on 'exit', (code, signal) ->
        next if code is 0 then ctx.OK else ctx.PASS
]



  