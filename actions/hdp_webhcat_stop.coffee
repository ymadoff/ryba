
lifecycle = require './hdp/lifecycle'

module.exports = []

module.exports.push (ctx) ->
  require('./hdp_webhcat').configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP WebHCat # Stop'
  lifecycle.webhcat_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
