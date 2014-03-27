
lifecycle = require './lib/lifecycle'

module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push (ctx) ->
  require('./webhcat').configure ctx

module.exports.push name: 'HDP WebHCat # Status', callback: (ctx, next) ->
  lifecycle.webhcat_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'

