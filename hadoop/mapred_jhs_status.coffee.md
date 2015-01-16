
# MapRed JobHistoryServer Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop JobHistoryServer # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.jhs_status ctx, next
