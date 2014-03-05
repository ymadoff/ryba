
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP DataNode # Start', callback: (ctx, next) ->
  return next new Error "Not an DataNode" unless ctx.has_module 'phyla/hdp/hdfs_dn'
  lifecycle.dn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS