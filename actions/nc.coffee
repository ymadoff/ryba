
module.exports = []

module.exports.push 'histi/actions/yum_epel'

###
nc
===
arbitrary TCP and UDP connections and listens.
###

module.exports.push module.exports.configure = (ctx) ->
  ctx.waitForConnection = (host, port, timeout, callback) ->
    if typeof timeout is 'function'
      callback = timeout
      timeout = null
    if timeout
      rand = Date.now()
      timedout = false
      clear = setTimeout ->
        timedout = true
        ctx.touch
          destination: "/tmp/#{rand}"
        , (err) ->
          # nothing to do
      , timeout
      ctx.execute
        cmd: "while [[ ! `nc -z -w5 #{host} #{port}` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
      , (err, executed) ->
        clearTimeout clear
        err = new Error "Reached timeout #{timeout}" if not err and timedout
        callback err
    else
      ctx.execute
        cmd: "while ! nc -z -w5 #{host} #{port}; do sleep 2; done;"
      , (err, executed) ->
        callback err

module.exports.push name: 'NC # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'nc'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

 