mecano = require 'mecano'
quote = require 'regexp-quote'

ntp = module.exports = []

ntp.push 'histi/actions/yum'

ntp.push (ctx) ->
  ctx.config.ntp ?= {}
  ctx.config.ntp.servers ?= ['pool.ntp.org']


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
    ctx.log "Synchronize the system clock with #{ctx.config.ntp.servers[0]}"
    # NTPD must not be started for ntpdate to work
    ctx.execute
      cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
    , (err) ->
      return next err if err
      ctx.log "Start the NTP service"
      ctx.service
        name: 'ntp'
        srv_name: 'ntpd'
        action: 'start'
      , (err, serviced) ->
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




