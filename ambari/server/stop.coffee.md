mecano = require 'mecano'
module.exports = []
 
module.exports.push name: 'Ambari Server # Stop', timeout: -1, label_true: 'STOPPED', handler: (ctx, next) ->
  ctx.service
    name: 'ambari-server'
    action: 'stop'
  , next