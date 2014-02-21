
lifecycle = require './lib/lifecycle'
hdp_zookeeper = require './zookeeper'
module.exports = []

module.exports.push (ctx) ->
  require('./zookeeper').configure ctx

###
Start ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push name: 'HDP ZooKeeper # Status', callback: (ctx, next) ->
  lifecycle.zookeeper_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'

