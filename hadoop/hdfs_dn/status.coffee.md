
# Hadoop HDFS DataNode Status

Display the status of the NameNode as "STARTED" or "STOPPED".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS DN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.dn_status ctx, next

## Dependencies

    lifecycle = require '../../lib/lifecycle'
