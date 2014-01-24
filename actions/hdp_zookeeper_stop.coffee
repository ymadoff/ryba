
lifecycle = require './hdp/lifecycle'
hdp_zookeeper = require './hdp_zookeeper'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_zookeeper').configure ctx

###
Stop ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push name: 'HDP # Stop ZooKeeper', callback: (ctx, next) ->
  {zookeeper_user} = ctx.config.hdp
  lifecycle.zookeeper_stop ctx, (err, stoped) ->
    next err, if stoped then ctx.OK else ctx.PASS

