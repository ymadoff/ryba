
# Hadoop HDFS DataNode Status

Display the status of the NameNode as "STARTED" or "STOPPED".

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_dn').configure

    module.exports.push name: 'HDFS DN # Status', callback: (ctx, next) ->
      lifecycle.dn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
