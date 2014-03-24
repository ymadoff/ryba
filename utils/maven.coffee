
###
Maven
=====

Currently being written, not yet registered in any config.

###

module.exports = []

###
Configuration
-------------
###
module.exports.push (ctx) ->
  ctx.config.maven ?= {}
  ctx.config.maven.source ?= 'http://mirror.olnevhost.net/pub/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz'

###
Installation
------------
###
module.exports.push (ctx, next) ->
  @name 'Maven # Installation'
  ctx.download
    source: ctx.config.maven.source
    destination: '/tmp/maven.tar.gz'
  , (err, executed) ->
    return next err if err
    ctx.extract
      source: '/tmp/maven.tar.gz'
      destination: '/usr/lib/maven'
    , (err, extracted) ->
      return next err if err
      next null, ctx.OK
