
###
Make
====
Install the GNU make utility to maintain groups of programs.

This action does not use any configuration.
###

mecano = require 'mecano'
module.exports = []

module.exports.push 'histi/actions/yum'

###
Package
-------
Install the service.
###
module.exports.push (ctx, next) ->
  @name 'Make # Package'
  @timeout 100000
  ctx.service
    name: 'make'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
