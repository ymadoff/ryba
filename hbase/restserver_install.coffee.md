---
title: 
layout: module
---

# HBase RestServer

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./restserver').configure

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase REST Server          | 8080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 8085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HHBase RestServer # IPTables', callback: (ctx, next) ->
      {hbase_site} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase_site['hbase.rest.port'] or 8080, protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase_site['hbase.rest.info.port'] or 8085, protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'HBase RestServer # Service', callback: (ctx, next) ->
      ctx.service
        name: 'hbase-rest'
      , next