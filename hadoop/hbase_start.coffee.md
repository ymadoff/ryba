---
title: 
layout: module
---

# HBase Start

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./hbase').configure

## Start HBase Master

Execute these commands on the HBase Master host machine.

    module.exports.push name: 'HDP HBase Master # Start', callback: (ctx, next) ->
      return next() unless ctx.has_module 'riba/hadoop/hbase_master'
      lifecycle.hbase_master_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

## Start HBase Region Server

Execute these commands on all RegionServers

    module.exports.push name: 'HDP HBase RegionServer # Start', callback: (ctx, next) ->
      return next() unless ctx.has_module 'riba/hadoop/hbase_regionserver'
      lifecycle.hbase_regionserver_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
