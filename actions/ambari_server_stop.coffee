
mecano = require 'mecano'
module.exports = []

module.exports.push name: 'Ambari Server # Stop', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'ambari-server'
    action: 'stop'
  , (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

