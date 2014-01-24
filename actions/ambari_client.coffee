
###
Ambari Client
###
request = require 'request'
module.exports = []

module.exports.push (ctx) ->
  ctx.config.ambari ?= {}
  throw new Error 'Property "ambari.name" is required' unless ctx.config.ambari.name

###
Wait
----
###
module.exports.push name: 'Ambari Client # Wait', timeout: -1, callback: (ctx, next) ->
    server = ctx.hosts_with_module 'histi/actions/ambari_server', 1
    {name} = ctx.config.ambari
    ready = ->
      request
        method: 'get'
        url: "http://#{server[0]}:8080/api/v1/clusters/#{name}"
        auth:
          username: 'admin'
          password: 'admin'
          sendImmediately: true
      , (err, res, body) ->
        return next err if err
        try
          body = JSON.parse body
        catch e then return next e
        registered = false
        if body.status isnt 404
          for host in body.hosts
            continue unless host.Hosts.host_name is ctx.config.host
            registered = true
        return next null, ctx.OK if registered
        ctx.log 'Retry in 5s'
        setTimeout ready, 5000
    ready()

module.exports.push name: 'Ambari Client # Startup', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'ambari-agent'
    startup: true
    action: 'start'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS







