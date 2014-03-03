
###
Connection
----------
Prepare the system to receive password-less root login and 
initialize an SSH connection.
###

{merge} = require 'mecano/lib/misc'
connect = require 'superexec/lib/connect'
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
  
module.exports.push name: 'Bootstrap # Connection', timeout: -1, callback: (ctx, next) ->
  close = -> ctx.ssh?.end()
  ctx.run.on 'error', close
  ctx.run.on 'end', close
  attempts = 0
  do_ssh = ->
    attempts++
    ctx.log "SSH login #{attempts}"
    config = merge {}, ctx.config.bootstrap,
      username: 'root'
      password: null
    connect config, (err, connection) ->
      if attempts isnt 0 and err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
        ctx.log 'Wait for reboot'
        return setTimeout do_ssh, 1000
      return do_collect() if err and attempts is 1
      return next err if err
      ctx.log "SSH connected"
      ctx.ssh = connection
      next null, ctx.PASS
  do_collect = ->
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
  do_ssh()


