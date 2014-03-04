
mecano = require 'mecano'
module.exports = []

module.exports.push 'phyla/core/yum'

module.exports.push name: 'GCC', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'gcc-c++'
  , (err, serviced) ->
    return next err if err
    next err, if serviced then ctx.OK else ctx.PASS
