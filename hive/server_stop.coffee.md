
# Hive Server Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Stop Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'Hive & HCat # Stop Hive Server2', label_true: 'STOPED', callback: (ctx, next) ->
      lifecycle.hive_server2_stop ctx, next

## Stop Hive Metastore

Execute these commands on the Hive Metastore host machine.

    module.exports.push name: 'Hive & HCat # Stop Hive Metastore', label_true: 'STOPED', callback: (ctx, next) ->
      lifecycle.hive_metastore_stop ctx, next

## Stop Clean Logs

    module.exports.push name: 'Hive & HCat # Stop Clean Logs', label_true: 'CLEANED', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hive-hcat/*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hive/*'
        code_skipped: 1
      ], next

