
lifecycle = require './hdp/lifecycle'
hdp_zookeeper = require './hdp_zookeeper'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_zookeeper').configure ctx

###
Start ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push name: 'HDP # Start ZooKeeper', callback: (ctx, next) ->
  {zookeeper_user} = ctx.config.hdp
  lifecycle.zookeeper_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

