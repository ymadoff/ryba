
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
module.exports.push 'histi/actions/users'
module.exports.push 'histi/actions/proxy'

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
module.exports.push (ctx, next) ->
  ctx.config.curl ?= {}
  ctx.config.curl.merge ?= true
  ctx.config.curl.users = true
  ctx.config.curl.proxy = true
  ctx.config.curl.config ?= {}
  # Satitize config
  {config, proxy} = ctx.config.curl
  config.noproxy = config.noproxy.join ',' if config.noproxy
  config.proxy = ctx.config.proxy.http_proxy if proxy
  next()

###
User Configuration
------------------

Deploy the "~/.curlrc" file to each users.
###
module.exports.push (ctx, next) ->
  @name 'Curl # User Configuration'
  ok = false
  {merge, proxy, users, config} = ctx.config.curl
  work = (user, file, next)->
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
