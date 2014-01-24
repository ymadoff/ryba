
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_hdfs').configure ctx
  require('./hdp_yarn').configure ctx
  require('./hdp_mapred').configure ctx

module.exports.push name: 'HDP # Stop MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_mapred_jhs'
  lifecycle.jhs_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop NodeManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_yarn_nm'
  lifecycle.nm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop ResourceManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_yarn_rm'
  lifecycle.rm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop Datanode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_dn'
  lifecycle.dn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop Secondary NameNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_snn'
  lifecycle.snn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Stop Namenode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_nn'
  lifecycle.nn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
