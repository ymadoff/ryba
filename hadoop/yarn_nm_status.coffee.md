
# YARN NodeManager Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push (ctx) ->
      require('./yarn_nm').configure ctx

    module.exports.push name: 'Hadoop NodeManager # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.nm_status ctx, next

