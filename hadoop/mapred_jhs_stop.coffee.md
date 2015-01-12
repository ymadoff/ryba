
# MapRed JobHistoryServer Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop JobHistoryServer # Stop', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.jhs_stop ctx, next
