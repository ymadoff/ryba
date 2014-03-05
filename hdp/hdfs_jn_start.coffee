
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP JournalNode # Start', callback: (ctx, next) ->
  lifecycle.jn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS
