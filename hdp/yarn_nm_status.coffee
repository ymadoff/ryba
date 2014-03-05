
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./yarn').configure ctx

module.exports.push name: 'HDP NodeManager # Status', callback: (ctx, next) ->
  lifecycle.nm_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'

