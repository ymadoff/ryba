
lifecycle = require './hdp/lifecycle'

module.exports = []

module.exports.push (ctx) ->
  require('./hdp_webhcat').configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP WebHCat # Start'
  lifecycle.webhcat_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS
