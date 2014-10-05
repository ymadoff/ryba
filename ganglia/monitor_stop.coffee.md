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
      # ctx.execute
      #   cmd: "/etc/init.d/hdp-gmond stop"
      # , (err, executed) ->
      #   next err, if executed then ctx.OK else ctx.PASS
      ctx.service
        # name: 'ganglia-gmond-3.5.0-99'
        srv_name: 'hdp-gmond'
        action: 'stop'
      , next

