
module.exports = []

###
nc
===
arbitrary TCP and UDP connections and listens.
###

module.exports.push module.exports.configure = (ctx) ->
  ctx.waitForConnection = (host, port, callback) ->
    ctx.execute
      cmd: "while ! nc -z -w5 #{host} #{port}; do sleep 2; done;"
    , (err, executed) ->
      callback err

module.exports.push name: 'NC # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'nc'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

 