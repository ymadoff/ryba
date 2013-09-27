
mecano = require 'mecano'

module.exports = (ctx, next) ->
  @name 'WebHDFS # Start'
  ctx.service
    name: 'webhdfs'
    action: 'start'
  , (err, serviced) ->
    return next err, if serviced then ctx.OK else ctx.PASS
  