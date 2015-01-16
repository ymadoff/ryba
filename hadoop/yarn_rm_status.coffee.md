
# Hadoop YARN ResourceManager Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./yarn_rm').configure

    module.exports.push name: 'Yarn RM # Status', handler: (ctx, next) ->
      lifecycle.rm_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

