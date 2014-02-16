
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('./yarn').configure ctx
  require('./mapred').configure ctx

module.exports.push name: 'HDP # Stop MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/mapred_jhs'
  lifecycle.jhs_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop NodeManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/yarn_nm'
  lifecycle.nm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop ResourceManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/yarn_rm'
  lifecycle.rm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop DataNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/hdfs_dn'
  lifecycle.dn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop Secondary NameNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/hdfs_snn'
  lifecycle.snn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop NameNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/hdfs_nn'
  lifecycle.nn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop JournalNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/hdp/hdfs_jn'
  lifecycle.jn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
