
###
GIT
===

GIT - the stupid content tracker. The recipe will install 
the git client and configure each user. By default, unless
the "global" property is defined, the global property file
in "/etc/gitconfig" will not be created or modified.

###
each = require 'each'
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
ini = require 'ini'
proxy = require '../core/proxy'
module.exports = []
module.exports.push 'phyla/bootstrap'
module.exports.push 'phyla/core/users'

###
Configuration
-------------

*   `properties`
    Git configuration shared by all users and the global 
    configuration file.
*   `global`
    The configation properties used to generate 
    the global configuration file in "/etc/gitconfig" or `null`
    if no global configuration file should be created, default
    to `null`.
*   `merge`
    Whether or not to merge the 'git.config' content 
    with the one present on the server. Declared 
    configuration preveils over the already existing 
    one on the server.
*   `proxy`
    Inject proxy configuration as declared in the 
    proxy action, default is true

Configuration example:

This exemple will create a global configuration file 
in "/etc/gitconfig" and a user configuration file for 
user "a_user". It defines its own proxy configuration, disregarding
any settings from the proxy action.

```json
{...
  git:
    merge: true
    global: 
      user: @name 'default user', email: 'default_user@domain.com'
    users: 
      a_user:
        user: @name 'a user', email: 'a_user@domain.com'
        http:
          proxy: 'http://some.proxy:9823'
...}
```
###
module.exports.push (ctx) ->
  proxy.configure ctx
  {http_proxy} = ctx.config.proxy
  ctx.config.git ?= {}
  ctx.config.git.merge ?= true
  ctx.config.git.properties ?= {}
  ctx.config.git.proxy ?= true
  ctx.config.git.global ?= false
  ctx.config.git.global = {} if ctx.config.git.global is true
  ctx.config.git.properties.http ?= {}
  ctx.config.git.properties.http.proxy = http_proxy if ctx.config.git.proxy

###
Package
-------
Install the git package.
###
module.exports.push name: 'Git # Package', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'git'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

###
Config
------
Deploy the git configuration.
###
module.exports.push name: 'Git # Config', callback: (ctx, next) ->
  modified = 0
  {merge, properties, global} = ctx.config.git
  work = (user, file, config, next)->
    config = misc.merge {}, properties, config
    get = ->
      return write() unless merge
      misc.file.readFile ctx.ssh, file, (err, properties) ->
        return next err if err and err.code isnt 'ENOENT'
        properties = if err or not properties then {} else ini.parse properties
        config = misc.merge {}, properties, config
        write()
    write = ->
      ctx.ini
        destination: file
        content: config
        uid: user.username
        gid: user.username
      , (err, written) ->
        modified += written
        next err
    get()
  doglobal = ->
    update = () ->
      work 'root', '/etc/gitconfig', global, (err) ->
        return next err if err
        dousers()
    remove = () ->
      misc.file.exists ctx.ssh, '/etc/gitconfig', (err, exists) ->
        return next err if err
        return dousers() unless exists
        misc.file.remove ctx.ssh, '/etc/gitconfig', (err) ->
          return next err if err
          modified++
          dousers()
    if global then update() else remove()
  dousers = () ->
    each(ctx.config.users)
    .on 'item', (user, next) ->
      return next() unless user.home
      file = "#{user.home}/.gitconfig"
      work user, file, {}, next
    .on 'both', (err) ->
      next err, if modified then ctx.OK else ctx.PASS
  doglobal()

