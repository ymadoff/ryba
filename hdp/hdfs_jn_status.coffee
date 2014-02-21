

lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP # Status JournalNode', callback: (ctx, next) ->
  lifecycle.jn_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'