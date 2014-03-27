
mecano = require 'mecano'

module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push name: 'Telnet', callback: (ctx, next) ->
  ctx.service
    name: 'telnet'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
