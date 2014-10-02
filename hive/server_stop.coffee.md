---
title: 
layout: module
---

# Hive Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('../hadoop/core').configure ctx
      require('./server').configure ctx

## Stop Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'Hive & HCat # Stop Hive Server2', callback: (ctx, next) ->
      lifecycle.hive_server2_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

## Stop Hive Metastore

Execute these commands on the Hive Metastore host machine.

    module.exports.push name: 'Hive & HCat # Stop Hive Metastore', callback: (ctx, next) ->
      lifecycle.hive_metastore_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS

## Stop Clean Logs

    module.exports.push name: 'HDP HDFS DN # Stop Clean Logs', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute [
        cmd: 'rm /var/log/hive-hcat/*'
        code_skipped: 1
      ,
        cmd: 'rm /var/log/hive/*'
        code_skipped: 1
      ], (err, removed) ->
        next err, if removed then ctx.OK else ctx.PASS

