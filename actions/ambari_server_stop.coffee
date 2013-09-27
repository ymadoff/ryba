
mecano = require 'mecano'

module.exports = [
  (ctx, next) ->
    @name 'Ambari Server # Stop'
    @timeout -1
    ctx.service
      name: 'ambari-server'
      action: 'stop'
    , (err, stoped) ->
      next err, if stoped then ctx.OK else ctx.PASS
]
