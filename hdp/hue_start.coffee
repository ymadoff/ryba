
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hue').configure ctx

###
Stop Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push name: 'HDP Hue # Start', callback: (ctx, next) ->
  lifecycle.hue_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS


