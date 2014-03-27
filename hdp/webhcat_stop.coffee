
lifecycle = require './lib/lifecycle'

module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push (ctx) ->
  require('./webhcat').configure ctx

module.exports.push name: 'HDP WebHCat # Stop', callback: (ctx, next) ->
  lifecycle.webhcat_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS
