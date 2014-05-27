---
title: 
layout: module
---

# MapRed Client

    mkcmd = require './lib/mkcmd'

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'phyla/hadoop/yarn_client'

    module.exports.push module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      require('./mapred_').configure ctx

    module.exports.push 'phyla/hadoop/mapred'

    # module.exports.push name: 'HDP MapRed # Configuration', callback: (ctx, next) ->
    #   { hadoop_conf_dir, mapred_user, mapred_group, mapred } = ctx.config.hdp
    #   ctx.hconfigure
    #     destination: "#{hadoop_conf_dir}/mapred-site.xml"
    #     properties: mapred
    #     merge: true
    #     uid: mapred_user
    #     gid: mapred_group
    #   , (err, configured) ->
    #     return next err, if configured then ctx.OK else ctx.PASS 

    module.exports.push name: 'HDP MapRed # Wait JHS', timeout: -1, callback: (ctx, next) ->
      {mapred} = ctx.config.hdp
      # Layout is created by the MapReduce JHS server
      [hostname, port] = mapred['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen hostname, port, (err) ->
        next err, ctx.PASS

## Test JobTracker

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated 
by this action is not present on HDFS. Delete this directory 
to re-execute the check.

    module.exports.push name: 'HDP MapRed Client # Check', timeout: -1, callback: (ctx, next) ->
      # 100 records = 1Ko
      # 10 000 000 000 = 100 Go
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f #{ctx.config.host}-mapred/done; then exit 1; fi
        hdfs dfs -mkdir -p #{ctx.config.host}-mapred
        hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar teragen 100 #{ctx.config.host}-mapred/input
        if [ $? != "0" ]; then exit 1; fi
        hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar terasort #{ctx.config.host}-mapred/input #{ctx.config.host}-mapred/10gsort
        if [ $? != "0" ]; then exit 1; fi
        hdfs dfs -touchz #{ctx.config.host}-mapred/done
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        next err, if executed then ctx.OK else ctx.PASS


