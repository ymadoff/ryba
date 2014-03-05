
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP DataNode # Stop', callback: (ctx, next) ->
  return next new Error "Not an DataNode" unless ctx.has_module 'phyla/hdp/hdfs_dn'
  lifecycle.dn_stop ctx, (err, stopped) ->
    next err, if stopped then ctx.OK else ctx.PASS