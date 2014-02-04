
lifecycle = require './lib/lifecycle'

module.exports = []

module.exports.push (ctx) ->
  require('./webhcat').configure ctx

module.exports.push name: 'HDP WebHCat # Stop', callback: (ctx, next) ->
  lifecycle.webhcat_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
