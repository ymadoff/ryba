
module.exports = []

#module.exports.push 'phyla/actions/yum'

module.exports.push name: 'Network # restart', callback: (ctx, next) ->
  ctx.execute
    cmd: 'service network restart'
  , (err) ->
    next err, ctx.PASS
