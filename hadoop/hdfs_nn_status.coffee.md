
# Hadoop HDFS NameNode Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_nn').configure

    module.exports.push name: 'HDFS NN # Status NameNode', handler: (ctx, next) ->
      lifecycle.nn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'

    module.exports.push name: 'HDFS NN # Status ZKFC', handler: (ctx, next) ->
      lifecycle.zkfc_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
