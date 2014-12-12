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

    module.exports.push name: 'Hive & HCat Server # Start Metastore', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      {hive_site} = ctx.config.ryba
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive_site['javax.jdo.option.ConnectionURL']
      ctx.waitIsOpen host, port, (err) ->
        return next err if err
        lifecycle.hive_metastore_start ctx, next

## Start Server2

Execute these commands on the Hive Server2 host machine.

    module.exports.push name: 'Hive & HCat Server # Start Server2', timeout: -1, label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, next

