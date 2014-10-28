---
title: 
layout: module
---

# Zookeeper Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Wait Kerberos

    module.exports.push 'masson/core/krb5_client_wait'

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Start', callback: (ctx, next) ->
      lifecycle.zookeeper_start ctx, next

