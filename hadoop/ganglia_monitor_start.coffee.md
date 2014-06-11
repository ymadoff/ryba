---
title: 
layout: module
---

# Ganglia Monitor Start

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Monitor # Start', callback: (ctx, next) ->
      # ctx.execute
      #   cmd: "/etc/init.d/hdp-gmond start"
      # , (err, executed) ->
      #   next err, if executed then ctx.OK else ctx.PASS
      ctx.service
        name: 'ganglia-gmond-3.5.0-99'
        srv_name: 'hdp-gmond'
        action: 'start'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS


