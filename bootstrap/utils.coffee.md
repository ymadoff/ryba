---
title: 
layout: module
---

# Utils

    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    connect = require 'ssh2-exec/lib/connect'

    module.exports = []

    module.exports.push name: 'Bootstrap # Utils', required: true, callback: (ctx) ->
      ctx.reboot = (callback) ->
        attempts = 0
        wait = ->
          ctx.log 'Wait for reboot'
          return setTimeout ssh, 2000
        ssh = ->
          attempts++
          ctx.log "SSH login attempt: #{attempts}"
          config = merge {}, ctx.config.bootstrap,
            username: 'root'
            password: null
          connect config, (err, connection) ->
            if err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
              return wait()
            return callback err if err
            ctx.ssh = connection
            callback()
        ctx.log "Reboot"
        ctx.execute
          cmd: 'reboot\n'
        , (err, executed, stdout, stderr) ->
          return callback err if err
          wait()
      ctx.waitForExecution = () ->
        if typeof arguments[0] is 'string'
          ###
          Argument "cmd" is a string:   
          `waitForConnection(cmd, [options], callback)`
          ###
          cmd = arguments[0]
          options = arguments[1]
          callback = arguments[2]
        else if typeof arguments[0] is 'object'
          ###
          Argument "cmd" is a string:   
          `waitForConnection(options, callback)`
          ###
          options = arguments[0]
          callback = arguments[1]
          cmd = options.cmd
        if typeof options is 'function'
          callback = options
          options = {}
        options.interval ?= 2000
        options.code_skipped ?= 1
        ctx.log "Wait for command to execute"
        ctx.emit 'wait'
        running = false
        run = ->
          return if running
          running = true
          ctx.execute
            cmd: cmd
            code: options.code or 0
            code_skipped: options.code_skipped
          , (err, ready, stdout, stderr) ->
            running = false
            return if not err and not ready
            return callback err if err
            clearInterval clear if clear
            ctx.emit 'waited'
            callback err, stdout, stderr
        clear = setInterval ->
          run()
        , options.interval
        run()
      inc = 0
      ctx.waitIsOpen = ->
        if typeof arguments[0] is 'string'
          ###
          Argument "host" is a string and argument "port" is a number:   
          `waitForConnection(host, port, [options], callback)`
          ###
          servers = [host: arguments[0], port: arguments[1]]
          options = arguments[2]
          callback = arguments[3]
        else if Array.isArray(arguments[0]) and typeof arguments[1] is 'number'
          ###
          Argument "hosts" is an array of string and argument "port" is a number:   
          `waitForConnection(hosts, port, [options], callback)`
          ###
          servers = for h in arguments[0] then host: h, port: arguments[1]
          options = arguments[2]
          callback = arguments[3]
        else
          ###
          Argument "servers" is an array of object with the host and port properties:   
          `waitForConnection(servers, [options], callback)`
          ###
          servers = arguments[0]
          options = arguments[1]
          callback = arguments[2]
        if typeof options is 'function'
          callback = options
          options = {}
        each(servers)
        .parallel(true)
        .on 'item', (server, next) ->
          if options.timeout
            rand = Date.now() + inc++
            timedout = false
            clear = setTimeout ->
              timedout = true
              ctx.touch
                destination: "/tmp/#{rand}"
              , (err) -> # nothing to do
            , options.timeout
            cmd = "while [[ ! `bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
          else
            cmd = "while ! bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'; do sleep 2; done;"
            # cmd = "bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'"
          ctx.log "Wait for #{server.host} #{server.port}"
          ctx.emit 'wait', server.host, server.port
          ctx.execute
            cmd: cmd
          , (err, executed) ->
            clearTimeout clear if clear
            err = new Error "Reached timeout #{options.timeout}" if not err and timedout
            ctx.emit 'waited', server.host, server.port
            next err
        .on 'both', callback
      ctx.connect = (config, callback) ->
        ctx.connections ?= {}
        config = (ctx.config.servers.filter (s) -> s.host is config)[0] if typeof config is 'string'
        ctx.log "SSH connection to #{config.host}"
        return callback null, ctx.connections[config.host] if ctx.connections[config.host]
        config.username ?= 'root'
        config.password ?= null
        ctx.log "SSH connection initiated"
        connect config, (err, connection) ->
          return callback err if err
          ctx.connections[config.host] = connection
          close = (err) ->
            ctx.log "SSH connection closed for #{config.host}"
            ctx.log 'Error closing connection: '+ (err.stack or err.message) if err
            connection.end()
          ctx.on 'error', close
          ctx.on 'end', close
          # ctx.run.on 'error', close
          # ctx.run.on 'end', close
          callback null, connection





