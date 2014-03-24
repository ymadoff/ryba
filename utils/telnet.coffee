
mecano = require 'mecano'

module.exports = name: 'Telnet', callback: (ctx, next) ->
  ctx.service
    name: 'telnet'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
