
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_oozie_server').configure ctx

###
Stop Oozie
----------
Execute these commands on the Oozie server host machine
###
module.exports.push (ctx, next) ->
  {oozie_user, oozie_log_dir, oozie_server} = ctx.config.hdp
  return next() unless oozie_server
  @name "HDP Oozie # Stop"
  lifecycle.oozie_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
