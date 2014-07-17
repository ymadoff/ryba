---
title: 
layout: module
---

# MapRed Client

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/yarn_client'

    module.exports.push module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      require('./mapred').configure ctx

    module.exports.push 'ryba/hadoop/mapred'

    module.exports.push name: 'HDP MapRed # Wait JHS', timeout: -1, callback: (ctx, next) ->
      {mapred} = ctx.config.hdp
      # Layout is created by the MapReduce JHS server
      [hostname, port] = mapred['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen hostname, port, (err) ->
        next err, ctx.PASS

## Check

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated 
by this action is not present on HDFS. Delete this directory 
to re-execute the check.

    module.exports.push name: 'HDP MapRed Client # Check', timeout: -1, callback: (ctx, next) ->
      {force_check} = ctx.config.hdp
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
        not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d check-#{host}-mapred"
        trap_on_error: true
      , (err, executed, stdout) ->
        next err, if executed then ctx.OK else ctx.PASS

## Module Dependencies

    mkcmd = require './lib/mkcmd'



