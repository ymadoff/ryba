
# Hadoop HDFS JournalNode Status

Display the status of the JournalNode as "STARTED" or "STOPPED".

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_jn').configure

    module.exports.push name: 'HDFS JN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.jn_status ctx, next
