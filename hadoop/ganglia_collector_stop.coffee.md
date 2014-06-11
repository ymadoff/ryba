---
title: 
layout: module
---

# Ganglia Monitor Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Collector # Stop', callback: (ctx, next) ->
      # ctx.execute
      #   cmd: "/etc/init.d/hdp-gmetad stop"
      # , (err, executed) ->
      #   next err, if executed then ctx.OK else ctx.PASS
      ctx.service [
        name: 'httpd'
        action: 'stop'
      ,
        name: 'ganglia-gmetad-3.5.0-99'
        srv_name: 'hdp-gmetad'
        action: 'stop'
      ], (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS
