
###
Curl
====

The recipe will configure curl for each users.
###

each = require 'each'
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
ini = require 'ini'

module.exports = []

###
Dependencies: users, proxy
###
module.exports.push 'phyla/core/users'
module.exports.push 'phyla/core/yum'
module.exports.push 'phyla/core/proxy'

###
Configuration
-------------

*   `merge`   
    Wether or not to merge the 'git.config' content 
    with the one present on the server. Declared configuration 
    preveils over the already existing one on the server.
*   `proxy`   
    Inject proxy configuration as declared in the proxy 
    action, default is true
*   `users`   
    Create a config file for all users defined by the 
    user action, default is true
###
module.exports.push (ctx) ->
  require('./users').configure ctx
  require('./proxy').configure ctx
  ctx.config.curl ?= {}
  {curl} = ctx.config
  curl.merge ?= true
  curl.users = true
  curl.proxy = true
  curl.config ?= {}
  curl.check ?= 'http://www.apache.org'
  curl.check_match ?= /Welcome to The Apache Software Foundation/
  # Satitize config
  curl.config.noproxy = curl.config.noproxy.join ',' if curl.config.noproxy
  curl.config.proxy = ctx.config.proxy.http_proxy if curl.proxy

###
User Configuration
------------------

Deploy the "~/.curlrc" file to each users.
###
module.exports.push name: 'Curl # User Configuration', callback: (ctx, next) ->
  ok = false
  {merge, users, config} = ctx.config.curl
  work = (user, file, next)->
    ctx.log "Write config into #{file}"
    ctx.ini
      content: config
      destination: file
      uid: user.username
      gid: null
      merge: merge
    , (err, written) ->
      return next err if err
      ok = true if written
      next()
  each(ctx.config.users)
  .on 'item', (user, next) ->
    return next() unless users
    return next() unless user.home
    file = "#{user.home}/.curlrc"
    work user, file, next
  .on 'both', (err) ->
    next err, if ok then ctx.OK else ctx.PASS

module.exports.push name: 'Curl # Install', timeout: -1, callback: (ctx, next) ->
  # On centOS, curl is already here
  ctx.service
    name: 'curl'
  , (err, installed) ->
    next err, if installed then ctx.OK else ctx.PASS

module.exports.push name: 'Curl # Connection Check', callback: (ctx, next) ->
  {check, check_match, config} = ctx.config.curl
  return next null, ctx.INAPPLICABLE unless check
  ctx.execute
    cmd: "curl -s #{check}"
    stdout: null
  , (err, executed, stdout, stderr) ->
    return next err if err
    unless check_match.test stdout
      msg = "#{if config.proxy then 'Proxy' else 'Connection'} not active"
      return next new Error msg
    next null, ctx.PASS

###
Examples
--------

Will create a ".curlrc" file in each home directory with the same proxy configuration

```json
{...
  proxy: 
    host: 'proxy.hostname', password: 'xx'
  users: [
    {username: 'nfs', system: true}
    {username: 'big', password: 'big123', home: true, shell: true}
  ]
  curl: 
    users: true
...}
```

It use the proxy action as default and show how to overwrite on a per user basis only for users "root" and "big".

```json
{...
  proxy: 
    host: 'proxy.hostname', password: 'xx'
  curl:
    users:
      root: {}
      big: proxy: 'http://some.proxy:9823'
...}
```
###
