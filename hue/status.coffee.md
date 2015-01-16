
# Hue Status

    lifecycle = require '../lib/lifecycle'

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hue # Status', handler: (ctx, next) ->
      lifecycle.hue_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

