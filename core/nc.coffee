
each = require 'each'

module.exports = []

module.exports.push 'phyla/core/yum_epel'

###
nc
===
arbitrary TCP and UDP connections and listens.
###

module.exports.push module.exports.configure = (ctx) ->
  return if ctx.nc_configured
  ctx.nc_configured = true
  inc = 0
  ctx.waitForExecution = () ->
    if typeof arguments[0] is 'string'
      ###
      Argument "cmd" is a string:   
      `waitForConnection(cmd, [options], callback)`
      ###
      cmd = arguments[0]
      options = arguments[1]
      callback = arguments[2]
    else if typeof arguments[0] is 'object'
      ###
      Argument "cmd" is a string:   
      `waitForConnection(options, callback)`
      ###
      options = arguments[0]
      callback = arguments[1]
      cmd = options.cmd
    if typeof options is 'function'
      callback = options
      options = {}
    options.interval ?= 2000
    options.code_skipped ?= 1
    ctx.log "Wait for command to execute"
    ctx.emit 'wait'
    running = false
    run = ->
      return if running
      running = true
      ctx.execute
        cmd: cmd
        code: options.code or 0
        code_skipped: options.code_skipped
      , (err, ready, stdout, stderr) ->
        running = false
        return if not err and not ready
        return callback err if err
        clearInterval clear if clear
        ctx.emit 'waited'
        callback err, stdout, stderr
    clear = setInterval ->
      run()
    , options.interval
    run()
  ###
  Options include:   
  *   `timeout`
  ###
  ctx.waitForConnection = () ->
    if typeof arguments[0] is 'string'
      ###
      Argument "host" is a string and argument "port" is a number:   
      `waitForConnection(host, port, [options], callback)`
      ###
      servers = [host: arguments[0], port: arguments[1]]
      options = arguments[2]
      callback = arguments[3]
    else if Array.isArray(arguments[0]) and typeof arguments[1] is 'number'
      ###
      Argument "hosts" is an array of string and argument "port" is a number:   
      `waitForConnection(hosts, port, [options], callback)`
      ###
      servers = for h in arguments[0] then host: h, port: arguments[1]
      options = arguments[2]
      callback = arguments[3]
    else
      ###
      Argument "servers" is an array of object with the host and port properties:   
      `waitForConnection(servers, [options], callback)`
      ###
      servers = arguments[0]
      options = arguments[1]
      callback = arguments[2]
    if typeof options is 'function'
      callback = options
      options = {}
    each(servers)
    .parallel(true)
    .on 'item', (server, next) ->
      if options.timeout
        rand = Date.now() + inc++
        timedout = false
        clear = setTimeout ->
          timedout = true
          ctx.touch
            destination: "/tmp/#{rand}"
          , (err) -> # nothing to do
        , options.timeout
        cmd = "while [[ ! `nc -z -w5 #{server.host} #{server.port}` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
      else
        cmd = "while ! nc -z -w5 #{server.host} #{server.port}; do sleep 2; done;"
      ctx.log "Wait for #{server.host} #{server.port}"
      ctx.emit 'wait', server.host, server.port
      ctx.execute
        cmd: cmd
      , (err, executed) ->
        clearTimeout clear if clear
        err = new Error "Reached timeout #{options.timeout}" if not err and timedout
        ctx.emit 'waited', server.host, server.port
        next err
    .on 'both', callback


module.exports.push name: 'NC # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'nc'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

 