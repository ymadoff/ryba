---
title: 
layout: module
---

# Ganglia Monitor Stop

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Monitor # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'hdp-gmond'
        action: 'stop'
      , next

