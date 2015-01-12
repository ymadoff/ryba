
# YARN NodeManager Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm_wait'
    module.exports.push require('./yarn').configure

    module.exports.push name: 'Hadoop NodeManager # Start Server', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.nm_start ctx, next
