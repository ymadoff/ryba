
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hdfs').configure ctx
  require('./hdp_yarn').configure ctx
  require('./hdp_mapred').configure ctx

module.exports.push (ctx, next) ->
  {namenode} = ctx.config.hdp
  return next() unless namenode
  @name "HDP # Start Namenode"
  lifecycle.nn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {secondary_namenode} = ctx.config.hdp
  return next() unless secondary_namenode
  @name "HDP # Start Secondary NameNode"
  lifecycle.snn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {datanode} = ctx.config.hdp
  return next() unless datanode
  @name "HDP # Start Datanode"
  lifecycle.dn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {resourcemanager} = ctx.config.hdp
  return next() unless resourcemanager
  @name "HDP # Start ResourceManager"
  lifecycle.rm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {nodemanager} = ctx.config.hdp
  return next() unless nodemanager
  @name "HDP # Start NodeManager"
  lifecycle.nm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {jobhistoryserver} = ctx.config.hdp
  return next() unless jobhistoryserver
  @name "HDP # Start MapReduce HistoryServer"
  lifecycle.jhs_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS


