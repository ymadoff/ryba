---
title: 
layout: module
---

    each = require 'each'

# Zookeeper Start

    lifecycle = require './lib/lifecycle'
    hdp_zookeeper = require './zookeeper'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./zookeeper').configure ctx
      # inc = 0
      # ctx.waitForConnection = () ->
      #   if typeof arguments[0] is 'string'
      #     ###
      #     Argument "host" is a string and argument "port" is a number:   
      #     `waitForConnection(host, port, [options], callback)`
      #     ###
      #     servers = [host: arguments[0], port: arguments[1]]
      #     options = arguments[2]
      #     callback = arguments[3]
      #   else if Array.isArray(arguments[0]) and typeof arguments[1] is 'number'
      #     ###
      #     Argument "hosts" is an array of string and argument "port" is a number:   
      #     `waitForConnection(hosts, port, [options], callback)`
      #     ###
      #     servers = for h in arguments[0] then host: h, port: arguments[1]
      #     options = arguments[2]
      #     callback = arguments[3]
      #   else
      #     ###
      #     Argument "servers" is an array of object with the host and port properties:   
      #     `waitForConnection(servers, [options], callback)`
      #     ###
      #     servers = arguments[0]
      #     options = arguments[1]
      #     callback = arguments[2]
      #   if typeof options is 'function'
      #     callback = options
      #     options = {}
      #   each(servers)
      #   .parallel(true)
      #   .on 'item', (server, next) ->
      #     if options.timeout
      #       rand = Date.now() + inc++
      #       timedout = false
      #       clear = setTimeout ->
      #         timedout = true
      #         ctx.touch
      #           destination: "/tmp/#{rand}"
      #         , (err) -> # nothing to do
      #       , options.timeout
      #       cmd = "while [[ ! `nc -z -w5 #{server.host} #{server.port}` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
      #     else
      #       cmd = "while ! nc -z -w5 #{server.host} #{server.port}; do sleep 2; done;"
      #     ctx.log "Wait for #{server.host} #{server.port}"
      #     ctx.emit 'wait', server.host, server.port
      #     ctx.execute
      #       cmd: cmd
      #     , (err, executed) ->
      #       clearTimeout clear if clear
      #       err = new Error "Reached timeout #{options.timeout}" if not err and timedout
      #       ctx.emit 'waited', server.host, server.port
      #       next err
      #   .on 'both', callback

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'HDP ZooKeeper # Start', callback: (ctx, next) ->
      {zookeeper_user} = ctx.config.hdp
      lifecycle.zookeeper_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

