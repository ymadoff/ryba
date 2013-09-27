
module.exports = (ctx, next) ->
  @name 'WebHDFS # Stop'
  ctx.service
    name: 'webhdfs'
    action: 'stop'
  , (err, serviced) ->
    return next err, if serviced then ctx.OK else ctx.PASS
  