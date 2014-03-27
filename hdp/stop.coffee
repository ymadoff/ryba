
lifecycle = require './lib/lifecycle'
module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('./yarn').configure ctx
  require('./mapred').configure ctx

module.exports.push name: 'HDP # Stop MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'phyla/hdp/mapred_jhs'
  lifecycle.jhs_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS
