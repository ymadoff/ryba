
module.exports = []

module.exports.push 'phyla/core/yum'

module.exports.push module.exports.configure = (ctx) ->


module.exports.push name: 'Glanglia Collector # Service', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'ganglia-gmond-3.5.0-99'
  ,
    name: 'ganglia-gmetad-3.5.0-99'
  ,
    name: 'ganglia-web-3.5.7-99'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'Glanglia Collector # Init Script', timeout: -1, callback: (ctx, next) ->
  ctx.upload [
    source: "#{__dirname}/ganglia/scripts/hdp-gmetad"
    destination: '/etc/init.d'
  ,
    source: "#{__dirname}/ganglia/scripts/hdp-gmond"
    destination: '/etc/init.d'
  ], (err, uploaded) ->
    next err, if uploaded then ctx.OK else ctx.PASS







