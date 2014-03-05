

lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP # Status NameNode', callback: (ctx, next) ->
  lifecycle.nn_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'

module.exports.push name: 'HDP # Status ZKFC', callback: (ctx, next) ->
  lifecycle.zkfc_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'
