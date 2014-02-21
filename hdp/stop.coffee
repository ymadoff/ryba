
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('./yarn').configure ctx
  require('./mapred').configure ctx

module.exports.push name: 'HDP # Stop MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/mapred_jhs'
  lifecycle.jhs_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop NodeManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/yarn_nm'
  lifecycle.nm_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop ResourceManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/yarn_rm'
  lifecycle.rm_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS
