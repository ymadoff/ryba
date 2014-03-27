
lifecycle = require './lib/lifecycle'

module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push (ctx) ->
  require('./zookeeper').configure ctx

module.exports.push name: 'HDP ZooKeeper # Status', callback: (ctx, next) ->
  lifecycle.zookeeper_status ctx, (err, running) ->
    next err, if running then 'STARTED' else 'STOPPED'

