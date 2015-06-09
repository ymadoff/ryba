
# Hadoop HDFS SecondaryNameNode Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS SNN # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.snn_stop ctx, next

    module.exports.push name: 'HDFS SNN # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-secondarynamenode-*'
        code_skipped: 1
        if: ctx.config.ryba.clean_logs
      .then next

## Dependencies

    lifecycle = require '../../lib/lifecycle'
