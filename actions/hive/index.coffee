
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
properties = require '../hadoop/lib/properties'

module.exports = []

module.exports.push (ctx) ->
  ctx.config.hive ?= {}
  ctx.config.hive.config ?= {}
  # The default connection string for the database that stores temporary hive statistics. (as of Hive 0.7.0)
  ctx.config.hive.config['hive.stats.dbconnectionstring'] ?= 'jdbc:derby:;databaseName=/tmp/TempStatsStore;create=true'
  ctx.config.hive.config['hive.support.concurrency'] ?= 'true'
  ctx.config.hive.config['hive.zookeeper.quorum'] ?= ''

module.exports.push (ctx, next) ->
  @name 'Hive'
  misc.file.readFile ctx.ssh, '/etc/hive/conf/hive-site.xml', (err, content) ->
    attrs = properties.parse content
    changes = false
    for k,v of ctx.config.hive.config
      if not v? and attrs[k]?
        delete attrs[k]
        changes = true
      else if attrs[k] isnt "#{v}"
        attrs[k] = "#{v}"
        changes = true
    return next null, ctx.PASS unless changes
    content = properties.stringify attrs
    ctx.write
      destination: '/etc/hive/conf/hive-site.xml'
      content: content
      backup: true
    , (err, written) ->
      next err, if written then ctx.OK else ctx.PASS
