
glob = require 'glob'
module.exports = []

module.exports.push 'phyla/core/yum'

module.exports.push module.exports.configure = (ctx) ->


module.exports.push name: 'Glanglia Monitor # Service', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'ganglia-gmond-3.5.0-99'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'Glanglia Monitor # Layout', timeout: -1, callback: (ctx, next) ->
  ctx.mkdir
    destination: '/usr/libexec/hdp/ganglia'
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'Glanglia Monitor # Objects', timeout: -1, callback: (ctx, next) ->
  glob "#{__dirname}/ganglia/objects/*.*", (err, files) ->
    files = for file in files then source: file, destination: /usr/libexec/hdp/ganglia/
    ctx.upload files, (err, uploaded) ->
      next err, if uploaded then ctx.OK else ctx.PASS

module.exports.push name: 'Glanglia Monitor # Init Script', timeout: -1, callback: (ctx, next) ->
  ctx.upload
    source: "#{__dirname}/ganglia/scripts/hdp-gmond"
    destination: '/etc/init.d'
  , (err, uploaded) ->
    next err, if uploaded then ctx.OK else ctx.PASS





