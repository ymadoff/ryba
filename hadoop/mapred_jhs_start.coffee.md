
# MapRed JobHistoryServer Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop MapRed JHS # Start', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.jhs_start ctx, next
