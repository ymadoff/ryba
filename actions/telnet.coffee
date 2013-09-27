
mecano = require 'mecano'

module.exports = (ctx, next) ->
  @name 'Telnet'
  ctx.service
    name: 'telnet'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
