---
title: 
layout: module
---

# Hive Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('../hadoop/core').configure ctx
      require('./server').configure ctx

## Start Hive Metastore

Execute these commands on the Hive Metastore host machine.

    module.exports.push name: 'HDP Hive # Start Metastore', timeout: -1, callback: (ctx, next) ->
      {hive_site} = ctx.config.hdp
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive_site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, (err) ->
        return next err if err
        lifecycle.hive_metastore_start ctx, (err, started) ->
          next err, if started then ctx.OK else ctx.PASS

## Start Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'HDP Hive # Start Server2', timeout: -1, callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

