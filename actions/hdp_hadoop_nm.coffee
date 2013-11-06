
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push 'histi/actions/hdp_yarn'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_yarn').configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop NM # Start'
  lifecycle.nm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS