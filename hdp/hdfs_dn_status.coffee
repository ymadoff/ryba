

lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP DataNode # Status', callback: (ctx, next) ->
  lifecycle.dn_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'
