
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  throw Error "Not a NameNode" unless ctx.has_module 'histi/hdp/hdfs_nn'

module.exports.push name: 'HDP NameNode # Start', callback: (ctx, next) ->
  lifecycle.nn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP NameNode # Start ZKFC', callback: (ctx, next) ->
  lifecycle.zkfc_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS