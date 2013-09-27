
###
Mahout
======

CDH4 Instruction
https://ccp.cloudera.com/display/CDH4DOC/Mahout+Installation
###
mecano = require 'mecano'
module.exports = []

###
Package
-------
Install the Mahout package
###
module.exports.push (ctx, next) ->
  @name 'Mahout # Package'
  ctx.service
    name: 'mahout'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

