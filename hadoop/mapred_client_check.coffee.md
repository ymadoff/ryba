
# MapRed Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_client').configure

## Wait JHS

    module.exports.push name: 'Hadoop MapRed # Wait JHS', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {mapred_site} = ctx.config.ryba
      [hostname, port] = mapred_site['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen hostname, port, (err) ->
        next err, ctx.PASS

## Check

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated 
by this action is not present on HDFS. Delete this directory 
to re-execute the check.

    module.exports.push name: 'Hadoop MapRed Client # Check', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {force_check} = ctx.config.ryba
      host = ctx.config.host.split('.')[0]
      # 100 records = 1Ko
      # 10 000 000 000 = 100 Go
      ctx.execute
        cmd: mkcmd.test ctx, """
        hdfs dfs -rm -r check-#{host}-mapred || true
        hdfs dfs -mkdir -p check-#{host}-mapred
        hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar teragen 100 check-#{host}-mapred/input
        hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar terasort check-#{host}-mapred/input check-#{host}-mapred/output
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d check-#{host}-mapred/output"
        trap_on_error: true
      , next

## Module Dependencies

    mkcmd = require '../lib/mkcmd'



