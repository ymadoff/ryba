
###
Netcat
======
Arbitrary TCP and UDP connections and listens.
###
mecano = require 'mecano'
actions = module.exports = []

actions.push 'histi/actions/yum'

###
Installation
------------
Install the service using YUM. Note, Netcat is present
by default on osx (with dev tools) and not on CentOs.
###
actions.push (ctx, next) ->
  ctx.name 'Netcat'
  ctx.service
    name: 'nc'
  , (err, installed) ->
    next err, if installed then ctx.OK else ctx.PASS
