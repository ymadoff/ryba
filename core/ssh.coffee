
###
SSH
===

###
each = require 'each'
module.exports = []

###
Requirements
------------
###
module.exports.push 'phyla/core/users'
module.exports.push 'phyla/core/yum'

###
Configuration
-------------
Configuration user the one define by the "users" action under the key "users".

```json
{ ...
  users: [{
    username: "root"
    authorized_keys: [ "ssh-rsa AAAA..ZZZZ me@email.com" ]
  },{
    username: "sweet"
    home: "/home/sweet/home" 
    authorized_keys: [ "ssh-rsa BBBB..YYYY you@email.com" ]
  }]
... }
```
###
module.exports.push (ctx, next) ->
  ctx.config.ssh ?= {}
  ctx.config.ssh.sshd_config ?= null
  ctx.config.users ?= []
  for user in ctx.config.users
    user.authorized_keys ?= []
  next()

###
Authorized Keys
---------------
Deploy authorized keys to users.
###
module.exports.push name: 'SSH # Authorized Keys', timeout: -1, callback: (ctx, next) ->
  ok = 0
  each(ctx.config.users)
  .on 'item', (user, next) ->
    return next() unless user.home
    ctx.mkdir 
      destination: "#{user.home}/.ssh"
      uid: user.username
      gid: null
      mode: 0o700 # was "permissions: 16832"
    , (err, created) ->
      return next err if err
      ctx.write
        destination: "#{user.home}/.ssh/authorized_keys"
        content: user.authorized_keys.join '\n'
        uid: user.username
        gid: null
        mode: 0o600
      , (err, written) ->
        return next err if err
        ok++ if written
        next()
  .on 'both', (err) ->
    next err, if ok then ctx.OK else ctx.PASS

module.exports.push name: 'SSH # Configure', timeout: -1, callback: (ctx, next) ->
  {sshd_config} = ctx.config.ssh
  return next() unless sshd_config
  write = []
  for k, v of sshd_config
    write.push
      match: new RegExp "^#{k}.*$", 'mg'
      replace: "#{k} #{v}"
      append: true
  ctx.log 'Write configuration in /etc/ssh/sshd_config'
  ctx.write
    write: write
    destination: '/etc/ssh/sshd_config'
  , (err, written) ->
    return next err if err
    return next null, ctx.PASS unless written
    ctx.log 'Restart sshd'
    ctx.service
      name: 'openssh'
      srv_name: 'sshd'
      action: 'restart'
    , (err, restarted) ->
      next err, ctx.OK

###
Private Keys
------------
Deploy id_rsa keys to users.
###
module.exports.push name: 'SSH # Private RSA Key', timeout: -1, callback: (ctx, next) ->
  ok = false
  each(ctx.config.users)
  .on 'item', (user, next) ->
    return next() unless user.home
    return next new Error "Property rsa_pub required if rsa defined" if user.rsa and not user.rsa_pub
    return next new Error "Property rsa required if rsa_pub defined" if user.rsa_pub and not user.rsa
    return next() unless user.rsa
    ctx.write
      destination: "#{user.home}/.ssh/id_rsa"
      content: user.rsa
      uid: user.username
      gid: null
      mode: 0o600
    , (err, written) ->
      return next err if err
      ok = true if written
      ctx.write
        destination: "#{user.home}/.ssh/id_rsa.pub"
        content: user.rsa_pub
        uid: user.username
        gid: null
        mode: 0o600
      , (err, written) ->
        return next err if err
        ok = true if written
        next()
  .on 'both', (err) ->
    next err, if ok then ctx.OK else ctx.PASS

module.exports.push name: 'SSH # Banner', timeout: 100000, callback: (ctx, next) ->
  {banner} = ctx.config.ssh
  return next() unless banner
  ctx.log 'Upload banner content'
  banner.content += '\n\n' if banner.content
  ctx.upload banner, (err, uploaded) ->
    return next err if err
    ctx.log 'Write banner path to configuration'
    ctx.write
      match: new RegExp "^Banner.*$", 'mg'
      replace: "Banner #{banner.destination}"
      append: true
      destination: '/etc/ssh/sshd_config'
    , (err, written) ->
      return next err if err
      return next null, ctx.PASS if not written and not uploaded
      ctx.log 'Restarting SSH'
      ctx.service
        name: 'openssh'
        srv_name: 'sshd'
        action: 'restart'
      , (err, restarted) ->
        next err, ctx.OK





