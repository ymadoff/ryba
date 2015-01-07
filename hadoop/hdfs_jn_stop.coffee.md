
# Hadoop HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its 
associated NameNodes.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_jn').configure

    module.exports.push name: 'HDFS JN # Stop', label_true: 'STOPPED', callback: (ctx, next) ->
      lifecycle.jn_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

    module.exports.push name: 'HDFS JN # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-journalnode-*'
        code_skipped: 1
      , next
