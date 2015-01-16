
# HBase Master Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Stop Server

Execute these commands on the HBase Master host machine.

    module.exports.push name: 'HBase Master # Stop Server', label_true: 'STOPPED', handler: (ctx, next) ->
      lifecycle.hbase_master_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'HBase Master # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hbase/*-master-*'
        code_skipped: 1
      , next
