
# Hadoop HDFS NameNode Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_nn').configure

    module.exports.push name: 'HDFS NN # Stop ZKFC', callback: (ctx, next) ->
      lifecycle.zkfc_stop ctx, next

    module.exports.push name: 'HDFS NN # Stop NameNode', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.nn_stop ctx, next

    module.exports.push name: 'HDFS NN # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hadoop-hdfs/*/*-namenode-*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hadoop-hdfs/*/*-zkfc-*'
        code_skipped: 1
      ], next
