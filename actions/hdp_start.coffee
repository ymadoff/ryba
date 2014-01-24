
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_hdfs').configure ctx
  require('./hdp_yarn').configure ctx
  require('./hdp_mapred').configure ctx

module.exports.push name: 'HDP # Start Namenode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_nn'
  lifecycle.nn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Start Secondary NameNode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_snn'
  lifecycle.snn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Start Datanode', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_hdfs_dn'
  lifecycle.dn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Start ResourceManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_yarn_rm'
  lifecycle.rm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Start NodeManager', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_yarn_nm'
  lifecycle.nm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP # Start MapReduce HistoryServer', callback: (ctx, next) ->
  return next() unless ctx.has_module 'histi/actions/hdp_mapred_jhs'
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS


