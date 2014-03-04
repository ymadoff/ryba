
mecano = require 'mecano'
module.exports = []

###
Bind Client
===========
###

module.exports.push 'phyla/core/yum'

###
BIND Utilities is not a separate package, it is a 
collection of the client side programs that are included 
with BIND-9.9.3. The BIND package includes the client 
side programs nslookup, dig and host.
###
module.exports.push name: 'Bind Client # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'bind-utils'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
