
###
Network
=======

Modify the various network related configuration files.

###

misc = require 'mecano/lib/misc'
network = module.exports = []

network.push (ctx) ->
  ctx.config.network ?= {}
  ctx.config.network.auto_hosts ?= false

###
Network # Hosts
---------------
Write the hostname resolution present in the configuration
under the "hosts" property into "/etc/hosts".
###
network.push name: 'Network # Hosts', callback: (ctx, next) ->
  {hosts, auto_hosts} = ctx.config.network
  content = ''
  if auto_hosts then for server in ctx.config.servers
    content += "#{server.ip} #{server.host}\n"
  for ip, hostnames of hosts
    content += "#{ip} #{hostnames}\n"
  ctx.write
    destination: '/etc/hosts'
    content: content
    mode: 0o666
    backup: true
  , (err, written) ->
    return next err, if written then ctx.OK else ctx.PASS

###
Network # Hostname
------------------
Declare the server hostname. On CentOs like system, the 
updated file is "/etc/sysconfig/network".
###
network.push name: 'Network # Hostname', callback: (ctx, next) ->
  ctx.write
    match: /^HOSTNAME=.*/mg
    replace: "HOSTNAME=#{ctx.config.host}"
    destination: '/etc/sysconfig/network'
  , (err, replaced) ->
    return next err if err
    return next null, ctx.PASS unless replaced 
    ctx.execute
      cmd: "hostname #{ctx.config.host} && service network restart"
    , (err, executed) ->
      next err, ctx.OK

###
Network # DNS resolv
--------------------
Write the DNS configuration. On CentOs like system, the 
updated file is "/etc/resolv".

The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
is a set of routines in the C library that provide
access to the Internet Domain Name System (DNS). The
configuration file is considered a trusted source of DNS information
###
network.push name: 'Network # DNS Resolver', callback: (ctx, next) ->
  {resolv} = ctx.config.network
  return next null, ctx.INAPPLICABLE unless resolv
  # nameservers = []
  # re = /nameserver(.*)/g
  # while (match = re.exec resolv) isnt null
  #   nameservers.push match[1].trim()
  nameservers = ctx.hosts_with_module 'bind_server'
  # console.log nameservers, 53
  ctx.waitIsOpen nameservers, 53, (err) ->
    return next err if err
    ctx.write
      content: resolv
      destination: '/etc/resolv.conf'
      backup: true
    , (err, replaced) ->
      return next err, if replaced then ctx.OK else ctx.PASS


