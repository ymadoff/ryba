
each = require 'each'
mecano = require 'mecano'
actions = module.exports = []

actions.push 'phyla/actions/yum'

actions.push (ctx) ->
  ctx.config.services ?= []

actions.push name: 'Service # Install', timeout: -1, callback: (ctx, next) ->
  serviced = 0
  {services} = ctx.config
  each(services)
  .on 'item', (service, next) ->
    service = name: service if typeof service is 'string'
    ctx.service service, (err, s) ->
      serviced += s
      next err
  .on 'both', (err) ->
    next err, if serviced then ctx.OK else ctx.PASS
