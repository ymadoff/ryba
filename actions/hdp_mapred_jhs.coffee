
lifecycle = require './hdp/lifecycle'
mkcmd = require './hdp/mkcmd'
module.exports = []

module.exports.push 'histi/actions/hdp_mapred'

module.exports.push (ctx) ->
  require('./hdp_mapred').configure ctx

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push (ctx, next) ->
  {hadoop_group, yarn_user, mapred_user} = ctx.config.hdp
  @name 'HDP Hadoop JHS # HDFS layout'
  ok = false
  do_jobhistory_server = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d /mr-history; then exit 1; fi
      hadoop fs -mkdir -p /mr-history/tmp
      hadoop fs -chmod -R 1777 /mr-history/tmp
      hadoop fs -mkdir -p /mr-history/done
      hadoop fs -chmod -R 1777 /mr-history/done
      hadoop fs -chown -R #{mapred_user}:#{hadoop_group} /mr-history
      hadoop fs -mkdir -p /app-logs
      hadoop fs -chmod -R 1777 /app-logs 
      hadoop fs -chown #{yarn_user} /app-logs 
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_end()
  do_end = ->
    next null, if ok then ctx.OK else ctx.PASS
  do_jobhistory_server()

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop JHS # Start'
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS



