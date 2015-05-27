
# MapReduce Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/mapred_jhs/wait'
    module.exports.push require('./index').configure

## Check

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated
by this action is not present on HDFS. Delete this directory
to re-execute the check.

    module.exports.push name: 'MapReduce Client # Check', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {force_check} = ctx.config.ryba
      host = ctx.config.shortname
      # 100 records = 1Ko
      # 10 000 000 000 = 100 Go
      ctx.execute
        cmd: mkcmd.test ctx, """
        hdfs dfs -rm -r check-#{host}-mapred || true
        hdfs dfs -mkdir -p check-#{host}-mapred
        hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar teragen 100 check-#{host}-mapred/input
        hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar terasort check-#{host}-mapred/input check-#{host}-mapred/output
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d check-#{host}-mapred/output"
        trap_on_error: true
      .then next

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'
