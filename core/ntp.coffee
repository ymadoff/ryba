
quote = require 'regexp-quote'

ntp = module.exports = []

ntp.push 'phyla/core/yum'

###
Command `ntpq -p` should print:   
```
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+ntp1.domain.com     192.168.0.170     5 u   15  256  377    0.400   -2.950   3.127
*ntp2.domain.com     192.168.0.178     5 u  213  256  377    0.391   -2.409   2.785
```
###
ntp.push (ctx) ->
  ctx.config.ntp ?= {}
  ctx.config.ntp.servers ?= ['pool.ntp.org']
  ctx.config.ntp.lag ?= 2000


###
Installation
------------
Follow the procedure published on 
"http://www.cyberciti.biz/faq/howto-install-ntp-to-synchronize-server-clock/".
###
ntp.push name: 'NTP # Install', timeout: -1, callback: (ctx, next) -> 
  ctx.log 'Install the NTP service and turn on the service'
  ctx.service
    name: 'ntp'
    chk_name: 'ntpd'
    startup: true
  , (err, serviced) ->
    return next err if err
    return next null, ctx.PASS unless serviced
    # Here's good place to compare the date, maybe with the host maching:
    # if gap is greather than threehold, stop ntpd, ntpdate, start ntpd
    ctx.log "Synchronize the system clock with #{ctx.config.ntp.servers[0]}"
    # NTPD must not be started for ntpdate to work
    ctx.log "Sync clock on first install since ntpd isnt yet started"
    ctx.execute
      cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
    , (err) ->
      next err, ctx.OK

ntp.push name: 'NTP # Configure', callback: (ctx, next) ->
  write = []
  write.push
    match: /^(server [\d]+.*$)/mg
    replace: "#$1"
  for server in ctx.config.ntp.servers
    write.push
      match: new RegExp "^server #{quote server}$", 'mg'
      replace: "server #{server}"
      append: 'Please consider joining'
  ctx.write
    destination: '/etc/ntp.conf'
    write: write
    backup: true
  , (err, written) ->
    return next err if err
    return next null, ctx.PASS unless written
    ctx.service
      name: 'ntp'
      srv_name: 'ntpd'
      action: 'restart'
    , (err) ->
      next err, ctx.OK

ntp.push name: 'NTP # Start', timeout: -1, callback: (ctx, next) -> 
  ctx.log "Start the NTP service"
  ctx.service
    name: 'ntp'
    srv_name: 'ntpd'
    action: 'start'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

ntp.push name: 'NTP # Check', callback: (ctx, next) ->
  {lag} = ctx.config.ntp
  ctx.execute
    cmd: "date +%s"
  , (err, executed, stdout) ->
    return next err if err
    time = parseInt(stdout.trim(), 10) * 1000
    current_lag = Math.abs(new Date() - new Date(time))
    return next null, ctx.PASS if current_lag < lag
    ctx.log "Lag greater than #{lag}ms: #{current_lag}"
    ctx.service
      name: 'ntp'
      srv_name: 'ntpd'
      action: 'stop'
    , (err, serviced) ->
      return next err if err
      ctx.execute
        cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
      , (err) ->
        return next err if err
        ctx.service
          name: 'ntp'
          srv_name: 'ntpd'
          action: 'stop'
        , (err, serviced) ->
          next err, ctx.OK




