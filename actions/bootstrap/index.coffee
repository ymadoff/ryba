###
bootstrap
=========

Bootstrap will initialize an SSH connection accessible 
throught the context object as `ctx.ssh`. The connection is 
initialized with the root user.
###

leveldb = require 'level'
tty = require 'tty'
pad = require 'pad'
readline = require 'readline'
mecano = require 'mecano'
fs = require 'fs'
{merge} = require 'mecano/lib/misc'
connect = require 'superexec/lib/connect'
collect = require './collect'
bootstrap = require './bootstrap'
module.exports = []

###
Configuration
-------------
###
module.exports.push (ctx) ->
  ctx.config.bootstrap ?= {}
  ctx.config.bootstrap.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
  ctx.config.bootstrap.port ?= ctx.config.port or 22
  ctx.config.bootstrap.public_key ?= []
  if typeof ctx.config.bootstrap.public_key is 'string'
    ctx.config.bootstrap.public_key = [ctx.config.bootstrap.public_key]
  ctx.config.bootstrap.cmd ?= 'su -'

module.exports.push name: 'Bootstrap # Cache', callback: (ctx, next) ->
  ctx.config.bootstrap.cache ?= {}
  location = ctx.config.bootstrap.cache.location or './tmp'
  mecano.mkdir
    destination: location
  , (err, created) ->
    if ctx.shared.cache
      ctx.cache = ctx.shared.cache
      return next null, ctx.PASS
    db = leveldb location
    ctx.cache = ctx.shared.cache =
      db: db
      put: (key, value, callback) ->
        db.put key, value, callback
      get: (key, callback) ->
        db.get key, callback
    next null, ctx.PASS

###
Log
----
Gather system information
###
module.exports.push name: 'Bootstrap # Log', callback: (ctx, next) ->
  mecano.mkdir
    destination: './logs'
  , (err, created) ->
    return next err if err
    host = ctx.config.host.split('.').reverse().join('.')
    # Add log interface
    ctx.log = log = (msg) ->
      log.out.write "#{msg}\n"
    log.out = fs.createWriteStream "./logs/#{host}_out.log"
    log.err = fs.createWriteStream "./logs/#{host}_err.log"
    close = ->
      setTimeout ->
        log.out.close()
        log.err.close()
      , 100
    ctx.run.on 'end', close
    ctx.run.on 'action', (ctx, status) ->
      return unless status is ctx.STARTED
      msg = "\n#{ctx.action.name}\n#{pad ctx.action.name.length, '', '-'}\n"
      log.out.write msg
      log.err.write msg
    ctx.run.on 'error', (err) ->
      print = (err) ->
        log.err.write err.message
        log.err.write err.stack if err.stack
      print err
      if err.errors
        for error in err.errors then print error
      close()
    next null, ctx.PASS

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
    return callback null, ctx.connections[config.host] if ctx.connections[config.host]
    config.username ?= 'root'
    config.password ?= null
    connect config, (err, connection) ->
      return callback err if err
      ctx.connections[config.host] = connection
      close = -> connection.end()
      ctx.run.on 'error', close
      ctx.run.on 'end', close
      callback null, connection


###
Connection
----------
Prepare the system to receive password-less root login and 
initialize an SSH connection.
###
module.exports.push  name: 'Bootstrap # Connection', timeout: -1, callback: (ctx, next) ->
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

###
Server Info
----
Gather system information.
###
module.exports.push  name: 'Bootstrap # Server Info', callback: (ctx, next) ->
  mecano.exec
    ssh: ctx.ssh
    cmd: 'uname -snrvmo'
    stdout: ctx.log.out
    stderr: ctx.log.err
  , (err, executed, stdout, stderr) ->
    return next err if err
    #Linux hadoop1 2.6.32-279.el6.x86_64 #1 SMP Fri Jun 22 12:19:21 UTC 2012 x86_64 x86_64 x86_64 GNU/Linux
    match = /(\w+) (\w+) ([^ ]+)/.exec stdout
    ctx.kernel_name = match[1]
    ctx.nodename = match[2]
    ctx.kernel_release = match[3]
    ctx.kernel_version = match[4]
    ctx.processor = match[5]
    ctx.operating_system = match[6]
    next null, ctx.PASS

###
Mecano
----
Predefined Mecano functions with context related information.
For example, this:

  mecano.execute
    ssh: ctx.ssh
    cmd: 'ls -l'
    stdout: ctx.log.out
    stderr: ctx.log.err
  , (err, executed) ->
    ...

Is similiar to:

  ctx.execute
    cmd: 'ls -l'
  , (err, executed) ->
    ...
###
module.exports.push name: 'Bootstrap # Mecano', timeout: -1, callback:  (ctx, next) ->
  m = (action, options) ->
    options.ssh ?= ctx.ssh
    options.log ?= ctx.log
    options.stdout ?= ctx.log.out
    options.stderr ?= ctx.log.err
    # if action is 'service'
    options.installed = ctx.installed
    options.updates = ctx.updates
    options
  [ 'chmod', 'chown', 'copy', 'download', 'execute', 
    'extract', 'git', 'ini', 'krb5_addprinc', 'krb5_delprinc', 
    'ldap_acl', 'ldap_index', 'ldap_schema', 'link', 'mkdir', 
    'move', 'remove', 'render', 'service', 'touch', 
    'upload', 'write'
  ].forEach (action) ->
    ctx[action] = (goptions, options, callback) ->
      if arguments.length is 2
        callback = options
        options = goptions
        goptions = {parallel: true}
      if action is 'mkdir' and typeof options is 'string'
        options = m action, destination: options
      if Array.isArray options
        for opts, i in options
          options[i] = m action, opts
      else
        options = m action, options
      if action is 'service'
        mecano[action].call null, options, (err) ->
          unless err
            ctx.installed = arguments[2]
            ctx.updates = arguments[3]
          callback.apply null, arguments
      else
        # Some mecano actions rely on `callback.length`
        mecano[action].call null, goptions, options, callback
  next null, ctx.PASS












