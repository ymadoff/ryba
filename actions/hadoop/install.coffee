
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
properties = require '../hadoop/lib/properties'

module.exports = []

###
Configuration
-------------
###
module.exports.push (ctx, next) ->
  ctx.config.hadoop ?= {}
  ctx.config.hadoop.mapred ?= {}
  ctx.config.hadoop.mapred['mapreduce.job.counters.max'] ?= 120
  next()

###
MapReduce
---------
###
module.exports.push (ctx, next) ->
  @name 'Hadoop # MapReduce'
  misc.file.readFile ctx.ssh, '/etc/hadoop/conf/mapred-site.xml', (err, content) ->
    return next err if err
    attrs = properties.parse content
    changes = false
    for k,v of ctx.config.hadoop.mapred
      if not v? and attrs[k]?
        delete attrs[k]
        changes = true
      else if attrs[k] isnt "#{v}"
        attrs[k] = "#{v}"
        changes = true
    return next null, ctx.PASS unless changes
    content = properties.stringify attrs
    ctx.write
      destination: '/etc/hadoop/conf/mapred-site.xml'
      content: content
      backup: true
    , (err, written) ->
      next err, if written then ctx.OK else ctx.PASS


