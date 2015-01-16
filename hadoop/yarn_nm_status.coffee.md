
# YARN NodeManager Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'Hadoop NodeManager # Status', handler: (ctx, next) ->
      lifecycle.nm_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

