
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hue').configure ctx

###
Stop Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push name: 'HDP Hue # Stop', callback: (ctx, next) ->
  lifecycle.hue_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS


