
mecano = require 'mecano'
module.exports = []

module.exports.push 'histi/actions/yum'

module.exports.push (ctx, next) ->
  @name 'GCC'
  @timeout -1
  ctx.service
    name: 'gcc-c++'
  , (err, serviced) ->
    return next err if err
    next err, if serviced then ctx.OK else ctx.PASS
