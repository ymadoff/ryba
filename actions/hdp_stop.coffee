
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hdfs').configure ctx
  require('./hdp_yarn').configure ctx
  require('./hdp_mapred').configure ctx

module.exports.push (ctx, next) ->
  {jobhistoryserver} = ctx.config.hdp
  return next() unless jobhistoryserver
  @name "HDP # Stop MapReduce HistoryServer"
  lifecycle.jhs_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {nodemanager} = ctx.config.hdp
  return next() unless nodemanager
  @name "HDP # Stop NodeManager"
  lifecycle.nm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {resourcemanager} = ctx.config.hdp
  return next() unless resourcemanager
  @name "HDP # Stop ResourceManager"
  lifecycle.rm_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {datanode} = ctx.config.hdp
  return next() unless datanode
  @name "HDP # Stop Datanode"
  lifecycle.dn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {secondary_namenode} = ctx.config.hdp
  return next() unless secondary_namenode
  @name "HDP # Stop Secondary NameNode"
  lifecycle.snn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {namenode} = ctx.config.hdp
  return next() unless namenode
  @name "HDP # Stop Namenode"
  lifecycle.nn_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS
