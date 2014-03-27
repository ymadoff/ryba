
lifecycle = require './lib/lifecycle'
module.exports = []
module.exports.push 'phyla/bootstrap'
module.exports.push (ctx) ->
  require('./yarn').configure ctx

module.exports.push name: 'HDP NodeManager # Start', callback: (ctx, next) ->
  lifecycle.nm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS