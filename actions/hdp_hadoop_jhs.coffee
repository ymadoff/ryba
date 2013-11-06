
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push 'histi/actions/hdp_mapred'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_mapred').configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop JHS # Start'
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS