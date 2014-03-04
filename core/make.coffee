
###
Make
====
Install the GNU make utility to maintain groups of programs.

This action does not use any configuration.
###

mecano = require 'mecano'
module.exports = []

module.exports.push 'phyla/core/yum'

###
Package
-------
Install the service.
###
module.exports.push name: 'Make # Package', timeout: 100000, callback: (ctx, next) ->
  ctx.service
    name: 'make'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
