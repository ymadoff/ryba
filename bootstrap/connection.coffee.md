---
title: 
layout: module
---

# Connection

Prepare the system to receive password-less root login and 
initialize an SSH connection.

    {exec} = require 'child_process'
    {merge} = require 'mecano/lib/misc'
    connect = require 'ssh2-exec/lib/connect'
    collect = require './lib/collect'
    bootstrap = require './lib/bootstrap'

    module.exports = []
    module.exports.push 'phyla/bootstrap/log'

    module.exports.push (ctx) ->
      ctx.config.bootstrap ?= {}
      ctx.config.bootstrap.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
      ctx.config.bootstrap.port ?= ctx.config.port or 22
      ctx.config.bootstrap.public_key ?= []
      if typeof ctx.config.bootstrap.public_key is 'string'
        ctx.config.bootstrap.public_key = [ctx.config.bootstrap.public_key]
      ctx.config.bootstrap.cmd ?= 'su -'
      
    module.exports.push name: 'Bootstrap # Connection', required: true, timeout: -1, callback: (ctx, next) ->
      {private_key} = ctx.config.bootstrap
      close = -> ctx.ssh?.end()
      ctx.run.on 'error', close
      ctx.run.on 'end', close
      attempts = 0
      modified = false
      do_private_key = ->
        return do_ssh() unless private_key
        ctx.log "Place SSH private key inside \"~/.ssh\""
        process.nextTick ->
          exec """
          mkdir -p ~/.ssh
          chmod 700 ~/.ssh
          echo '#{private_key}' > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          """, (err, stdout, stderr) ->
            return next err if err
            do_ssh()
      do_ssh = ->
        attempts++
        ctx.log "SSH login #{attempts} to root@#{ctx.config.host}"
        config = merge {}, ctx.config.bootstrap,
          host: ctx.config.ip or ctx.config.host
          private_key: null # make sure "bootstap.private_key" isnt used by ssh2
          username: 'root'
          password: null
          readyTimeout: 120 * 1000 # default to 10s, now 2mn
        connect config, (err, connection) ->
          if attempts isnt 0 and err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
            ctx.log 'Wait for reboot'
            return setTimeout do_ssh, 1000
          return do_collect() if err and attempts is 1
          return next err if err
          ctx.log "SSH connected"
          ctx.ssh = connection
          next null, if modified then ctx.OK else ctx.PASS
      do_collect = ->
        modified = true
        ctx.log 'Collect login information'
        collect ctx.config.bootstrap, (err) ->
          return next err if err
          do_boot()
      do_boot = ->
        ctx.log 'Deploy ssh key'
        bootstrap ctx, (err) ->
          return next err if err
          ctx.log 'Reboot and login'
          do_ssh()
      do_private_key()


