
each = require 'each'

module.exports = []

module.exports.push 'histi/actions/yum_epel'

###
nc
===

`waitForConnection(host, port, [timeout], callback)`
`waitForConnection(hosts, port, [timeout], callback)`
`waitForConnection(hosts_ports, [timeout], callback)`

arbitrary TCP and UDP connections and listens.
###

module.exports.push module.exports.configure = (ctx) ->
  ctx.waitForConnection = (host, port, timeout, callback) ->
    if typeof host is 'string'
      options = [host: host, port: port]
    else if Array.isArray(host) and typeof port is 'number'
      options = for h in host then host: h, port: port
    else
      options = host
      callback = timeout
      timeout = port
    if typeof timeout is 'function'
      callback = timeout
      timeout = null

    each(options)
    .parallel(true)
    .on 'item', (option, next) ->
      if timeout
        rand = Date.now()
        timedout = false
        clear = setTimeout ->
          timedout = true
          ctx.touch
            destination: "/tmp/#{rand}"
          , (err) -> # nothing to do
        , timeout
        cmd = "while [[ ! `nc -z -w5 #{option.host} #{option.port}` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
      else
        cmd = "while ! nc -z -w5 #{option.host} #{option.port}; do sleep 2; done;"
      ctx.log "Wait for #{option.host} #{option.port}"
      ctx.run.emit 'wait', ctx, option.host, option.port
      ctx.execute
        cmd: cmd
      , (err, executed) ->
        clearTimeout clear if clear
        err = new Error "Reached timeout #{timeout}" if not err and timedout
        next err, ->
          ctx.run.emit 'waited', ctx, option.host, option.port
    .on 'both', callback
    # if timeout
    #   each(options)
    #   .parallel(true)
    #   .on 'item', (option, next) ->
    #     rand = Date.now()
    #     timedout = false
    #     clear = setTimeout ->
    #       timedout = true
    #       ctx.touch
    #         destination: "/tmp/#{rand}"
    #       , (err) -> # nothing to do
    #     , timeout
    #     ctx.log "Wait for #{option.host} #{option.port}"
    #     ctx.execute
    #       cmd: "while [[ ! `nc -z -w5 #{option.host} #{option.port}` ]] && [[ ! -f /tmp/#{rand} ]]; do sleep 2; done;"
    #     , (err, executed) ->
    #       clearTimeout clear
    #       err = new Error "Reached timeout #{timeout}" if not err and timedout
    #       next err
    #   .on 'both', callback
    # else
    #   each(options)
    #   .parallel(true)
    #   .on 'item', (option, next) ->
    #     ctx.log "Wait for #{option.host} #{option.port}"
    #     ctx.execute
    #       cmd: "while ! nc -z -w5 #{option.host} #{option.port}; do sleep 2; done;"
    #     , (err, executed) ->
    #       next err
    #   .on 'both', (err) ->
    #     callback err


module.exports.push name: 'NC # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'nc'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

 