
module.exports =
  nn_start: (ctx, callback) ->
    {hdfs_user} = ctx.config.hdp
    ctx.execute
      # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode"
      cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode\""
      code_skipped: 1
    , (err, started) ->
      callback err, started
  nn_running: (ctx, callback) ->
    {hdfs_pid_dir} = ctx.config.hdp
    ctx.execute
      cmd: "kill -0 `cat #{hdfs_pid_dir}/hadoop-hdfs-namenode.pid`"
      code_skipped: 1
    , callback