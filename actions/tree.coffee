
mecano = require 'mecano'

module.exports = (ctx, next) ->
  @name 'Tree'
  ctx.service
    name: 'tree'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
