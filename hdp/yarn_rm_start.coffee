
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./yarn').configure ctx

module.exports.push name: 'HDP ResourceManager # Start', callback: (ctx, next) ->
  lifecycle.rm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS