---
title: 
layout: module
---

# Hive Start

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./core').configure ctx
      require('./hive_server').configure ctx

## Start Hive Metastore

Execute these commands on the Hive Metastore host machine.

    module.exports.push name: 'HDP Hive # Start Metastore', timeout: -1, callback: (ctx, next) ->
      {hive_jdo_host, hive_jdo_port} = ctx.config.hdp
      ctx.waitIsOpen hive_jdo_host, hive_jdo_port, (err) ->
        return next err if err
        lifecycle.hive_metastore_start ctx, (err, started) ->
          next err, ctx.OK

## Start Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'HDP Hive # Start Server2', timeout: -1, callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, (err, started) ->
        next err, ctx.OK

