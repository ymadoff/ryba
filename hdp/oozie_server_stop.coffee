
lifecycle = require './lib/lifecycle'
module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push (ctx) ->
  require('./oozie_server').configure ctx

###
Stop Oozie
----------
Execute these commands on the Oozie server host machine
###
module.exports.push name: 'HDP Oozie # Stop', timeout: -1, callback: (ctx, next) ->
  return next() unless ctx.has_module 'phyla/hdp/oozie_server'
  lifecycle.oozie_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS
