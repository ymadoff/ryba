
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'
module.exports = []

module.exports.push 'histi/hdp/mapred'

module.exports.push (ctx) ->
  require('./mapred').configure ctx unless require('./mapred').configured

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push name: 'HDP Hadoop JHS # HDFS layout', callback: (ctx, next) ->
  {hadoop_group, yarn_user, mapred_user} = ctx.config.hdp
  ok = false
  do_jobhistory_server = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hdfs dfs -test -d /mr-history; then exit 1; fi
      hdfs dfs -mkdir -p /mr-history/tmp
      hdfs dfs -chmod -R 1777 /mr-history/tmp
      hdfs dfs -mkdir -p /mr-history/done
      hdfs dfs -chmod -R 1777 /mr-history/done
      hdfs dfs -chown -R #{mapred_user}:#{hadoop_group} /mr-history
      hdfs dfs -mkdir -p /app-logs
      hdfs dfs -chmod -R 1777 /app-logs 
      hdfs dfs -chown #{yarn_user} /app-logs 
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_end()
  do_end = ->
    next null, if ok then ctx.OK else ctx.PASS
  do_jobhistory_server()

module.exports.push name: 'HDP Hadoop JHS # Start', callback: (ctx, next) ->
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS



