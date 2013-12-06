
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_oozie_server').configure ctx

###
Start Oozie
-----
Execute these commands on the Oozie server host machine
###
module.exports.push (ctx, next) ->
  {oozie_user, oozie_log_dir, oozie_server} = ctx.config.hdp
  return next() unless oozie_server
  @name "HDP Oozie # Start"
  lifecycle.oozie_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

