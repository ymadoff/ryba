
{merge} = require 'mecano/lib/misc'
connect = require 'superexec/lib/connect'

module.exports = []

module.exports.push name: 'Bootstrap # Utils', callback: (ctx) ->
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