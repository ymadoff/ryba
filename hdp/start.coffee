
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  # require('./hdfs').configure ctx
  require('./yarn').configure ctx
  require('./mapred').configure ctx

module.exports.push name: 'HDP # Start MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'phyla/hdp/mapred_jhs'
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS


