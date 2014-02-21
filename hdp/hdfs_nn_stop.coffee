
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('./yarn').configure ctx
  require('./mapred').configure ctx

module.exports.push name: 'HDP # Stop NameNode', callback: (ctx, next) ->
  return next new Error "Not a NameNode" unless ctx.has_module 'histi/hdp/hdfs_nn'
  lifecycle.nn_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS