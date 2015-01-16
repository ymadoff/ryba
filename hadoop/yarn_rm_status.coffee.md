
# Hadoop YARN ResourceManager Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./yarn_rm').configure

    module.exports.push name: 'Yarn RM # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.rm_status ctx, next

