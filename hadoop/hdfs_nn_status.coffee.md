
# Hadoop HDFS NameNode Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_nn').configure

    module.exports.push name: 'HDFS NN # Status NameNode', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.nn_status ctx, next

    module.exports.push name: 'HDFS NN # Status ZKFC', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      lifecycle.zkfc_status ctx, next
