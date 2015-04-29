
# Hadoop HDFS SecondaryNameNode Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS SNN # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.snn_stop ctx, next

    module.exports.push name: 'HDFS SNN # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-secondarynamenode-*'
        code_skipped: 1
      , next

## Module Dependencies

    lifecycle = require '../../lib/lifecycle'
