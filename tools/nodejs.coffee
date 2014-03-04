
###

NodeJs
======

Deploy multiple version of [NodeJs] using [N].

Configuration
-------------

*   version: any NodeJs version with the addition of "latest" and "stable", see the [N] documentation for more information, default to "stable"

[nodejs]: http://www.nodejs.org
[n]: https://github.com/visionmedia/n
###

ini = require 'ini'
each = require 'each'
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
proxy = require '../core/proxy'

nodejs = module.exports = []

###
Dependencies: users, proxy
###
nodejs.push 'phyla/core/users'
nodejs.push 'phyla/tools/git'
# nodejs.push 'phyla/core/proxy'

###
Configuration
-------------
###
nodejs.push (ctx, next) ->
  proxy.configure ctx
  ctx.config.nodejs ?= {}
  ctx.config.nodejs.version ?= 'stable'
  ctx.config.nodejs.merge ?= true
  ctx.config.nodejs.http_proxy ?= ctx.config.proxy.http_proxy
  ctx.config.nodejs.https_proxy ?= ctx.config.proxy.https_proxy
  ctx.config.nodejs.users ?= true
  ctx.config.nodejs.config ?= {}
  ctx.config.nodejs.config.registry ?= 'http://registry.npmjs.org/'
  next()

###
N Installation
--------------
N is a Node.js binary management system, similar to nvm and nave.
###
nodejs.push name: 'Node.js # N', timeout: 100000, callback: (ctx, next) ->
  # Accoring to current test, proxy env var arent used by ssh exec
  {http_proxy, https_proxy} = ctx.config.nodejs
  env = {}
  env.http_proxy = http_proxy if http_proxy
  env.https_proxy = https_proxy if https_proxy
  ctx.execute
    env: env
    cmd: """
    export http_proxy=#{http_proxy or ''}
    export https_proxy=#{http_proxy or ''}
    cd /tmp
    git clone https://github.com/visionmedia/n.git
    cd n
    make install
    """
    not_if_exists: '/usr/local/bin/n'
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Node.js Installation
--------------------
Multiple installation of Node.js may coexist.
###
nodejs.push name: 'Node.js # installation', timeout: -1, callback: (ctx, next) ->
  ctx.execute
    cmd: "n #{ctx.config.nodejs.version}"
  , (err, executed) ->
    next err, if executed is 0 then ctx.OK else ctx.PASS

###
NPM configuration
-----------------
###
nodejs.push name: 'Node.js # Npm Configuration', timeout: 100000, callback: (ctx, next) ->
  written = 0
  each(ctx.config.users)
  .on 'item', (user, next) ->
    return next() unless user.home
    file = "#{user.home}/.npmrc"
    remoteConfig = {}
    get = ->
      return write() unless ctx.config.nodejs.merge
      misc.file.readFile ctx.ssh, file, (err, config) ->
        return next err if err and err.code isnt 'ENOENT'
        config ?= ''
        config = ini.parse config
        remoteConfig = config
        write()
    write = ->
      config = ctx.config.nodejs.config
      if ctx.config.nodejs.proxy
        config.proxy = ctx.config.nodejs.proxy
      else 
        delete remoteConfig.proxy
      misc.merge remoteConfig, config
      config = ini.stringify config
      ctx.write
        destination: file
        content: config
        uid: user.username
        gid: null
      , (err, w) ->
        written++ if w
        next err
    get()
  .on 'both', (err) ->
    next err, if written then ctx.OK else ctx.PASS

