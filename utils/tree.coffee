

module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push name: 'Tree', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'tree'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
