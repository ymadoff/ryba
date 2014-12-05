---
title: 
layout: module
---

# YARN ResourceManager Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn_wait'
    module.exports.push require('./yarn_rm').configure

    module.exports.push name: 'Hadoop ResourceManager # Start Server', callback: (ctx, next) ->
      lifecycle.rm_start ctx, next

    module.exports.push name: 'Hadoop ResourceManager # Ensure Active/Standby', callback: (ctx, next) ->
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      return next() unless rm_hosts.length > 1 
      {active_rm_host} = ctx.config.ryba
      if active_rm_host is ctx.config.host

      

